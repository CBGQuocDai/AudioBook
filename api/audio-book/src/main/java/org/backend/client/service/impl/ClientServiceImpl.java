package org.backend.client.service.impl;


import io.jsonwebtoken.Claims;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.backend.auth.dto.response.TokenResponse;
import org.backend.auth.enums.OtpPurpose;
import org.backend.client.dto.request.ChangeEmailRequest;
import org.backend.client.dto.request.RegisterRequest;
import org.backend.client.dto.response.ClientResponse;
import org.backend.client.entity.Client;
import org.backend.client.enums.Tier;
import org.backend.client.mapper.ClientMapper;
import org.backend.client.repository.ClientRepository;
import org.backend.client.service.ClientService;
import org.backend.common.exception.BusinessException;
import org.backend.common.exception.ErrorCode;
import org.backend.common.util.EmailUtil;
import org.backend.common.util.JwtUtil;
import org.backend.common.util.OtpCodeUtil;
import org.backend.file.dto.FileDto;
import org.backend.file.entity.File;
import org.backend.file.repository.FileRepository;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.Objects;
import java.util.concurrent.TimeUnit;

/**
 * Service implementation for managing client profiles and account flows.
 * Handles database operations, redis caching for OTP codes, password hashing, and subscription verification.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class ClientServiceImpl implements ClientService {

    private final ClientRepository clientRepository;
    private final RedisTemplate<String, Object> cache;
    private final ClientMapper clientMapper;
    private final PasswordEncoder passwordEncoder;
    private final FileRepository fileRepository;
    private final JwtUtil jwtUtil;
    private final EmailUtil emailUtil;
    /**
     * {@inheritDoc}
     * Maps the registration request to a client entity, assigns a default avatar,
     * encodes the password, saves the client, and sends a verification OTP to the registered email.
     *
     * @param registerRequest the registration details of the new client
     * @throws BusinessException if the default avatar file is not found (ErrorCode.FILE_NOT_FOUND)
     *                           or if the email is already registered and active (ErrorCode.EMAIL_EXIST)
     */
    @Override
    public void register(RegisterRequest registerRequest) {
        Client c = clientMapper.registerRequestToEntity(registerRequest);
        File f = fileRepository.findById(4L).orElseThrow( () -> new BusinessException(ErrorCode.FILE_NOT_FOUND));
        c.setAvatarFile(f);
        c.setPassword(passwordEncoder.encode(c.getPassword()));
        Client temp  = clientRepository.findByEmail(c.getEmail());
        if(!Objects.isNull(temp)) {
            if (temp.getActive()) {
                throw new BusinessException(ErrorCode.EMAIL_EXIST);
            }
            temp.setName(c.getName());
            temp.setPassword(c.getPassword());
        } else  {
            clientRepository.save(c);
        }

        String code = OtpCodeUtil.generateOtpCode();
        cache.opsForValue().set(c.getEmail(),
                code, 5, TimeUnit.MINUTES);
    emailUtil.sendOtpEmail(
        c.getEmail(),
        code,
        "Xác thực tài khoản AudioBook",
        "Chúng tôi đã nhận yêu cầu tạo tài khoản. Vui lòng dùng mã OTP bên dưới để xác thực email.",
        5
    );
    }

    /**
     * {@inheritDoc}
     * Retrieves the profile info from the database based on the security context authentication.
     * Checks subscription details raw query to determine if the active tier is BASE or PREMIUM.
     *
     * @return the profile response containing authenticated client details and tier status
     * @throws BusinessException if the authenticated client is not found in the database (ErrorCode.USER_NOT_FOUND)
     */
    @Override
    public ClientResponse me() {
        String email = SecurityContextHolder.getContext().getAuthentication().getName();
        log.info("email: {}", email);
        Client c = clientRepository.findByEmailAndActive(email,true);
        if(Objects.isNull(c)) throw new BusinessException(ErrorCode.USER_NOT_FOUND);
        ClientResponse clientResponse = clientMapper.entityToResponse(c);
        boolean isPremium = clientRepository.isSubscriptionActiveRaw(clientResponse.getId())==1;
        log.debug("isPremium: {}", isPremium);
        if(isPremium) {
            clientResponse.setTier(Tier.PREMIUM);
        } else {
            clientResponse.setTier(Tier.BASE);
        }
        return clientResponse;
    }

    /**
     * {@inheritDoc}
     * Updates the name of the currently authenticated client and persists it to the database.
     *
     * @param name the new name for the client
     * @return the updated client profile information
     * @throws BusinessException if the authenticated user is not found in the database (ErrorCode.USER_NOT_FOUND)
     */
    @Override
    public ClientResponse changeName(String name) {
        String email = SecurityContextHolder.getContext().getAuthentication().getName();
        Client c = clientRepository.findByEmailAndActive(email,true);
        if(Objects.isNull(c)) throw new BusinessException(ErrorCode.USER_NOT_FOUND);
        c.setName(name);
        return clientMapper.entityToResponse(clientRepository.save(c));
    }

    /**
     * {@inheritDoc}
     * Checks if the target email is already registered and active. If not, generates an OTP,
     * stores it in the redis cache for 5 minutes, and sends a verification email to the target address.
     *
     * @param email the new email address to be verified
     * @throws BusinessException if the target email is already in use by an active account (ErrorCode.EMAIL_EXIST)
     */
    @Override
    public void preChangEmailRequest(String email) {
        if(!clientRepository.existsByEmailAndActive(email,true)){
            String code = OtpCodeUtil.generateOtpCode();
            cache.opsForValue().set(email, code,
                    5, TimeUnit.MINUTES);
            emailUtil.sendOtpEmail(
                    email,
                    code,
                    "Xác thực tài khoản AudioBook",
                    "Chúng tôi đã nhận yêu cầu tạo tài khoản. Vui lòng dùng mã OTP bên dưới để xác thực email.",
                    5
            );
        }
        else {
            throw new BusinessException(ErrorCode.EMAIL_EXIST);
        }
    }

    /**
     * {@inheritDoc}
     * Decodes the current token to find the old email, verifies that the OTP in the request
     * matches the cached OTP for the new email. On success, updates the database record,
     * invalidates/caches the old JWT token to prevent replay, and issues a new JWT.
     *
     * @param req the details containing the new email and the verification OTP code
     * @param token the current active JWT token of the authenticated client
     * @return a new token response containing the updated token and user information
     * @throws BusinessException if the OTP is missing, invalid, or expired (ErrorCode.OTP_INVALID)
     */
    @Override
    public TokenResponse changeEmail(ChangeEmailRequest req, String token) {
        Claims c = jwtUtil.getClaims(token);
        String oldEmail = c.getSubject();
        Client c1 = clientRepository.findByEmailAndActive(oldEmail,true);

        if(Objects.isNull(cache.opsForValue().get(req.getNewEmail()))) {
            throw new BusinessException(ErrorCode.OTP_INVALID);
        }
        String otp = (String) cache.opsForValue().get(req.getNewEmail());

        if(otp.equals(req.getOtp())) {
            c1.setEmail(req.getNewEmail());
            clientRepository.save(c1);
            cache.delete(req.getNewEmail());
            if(c.getExpiration().getTime() > System.currentTimeMillis()) {
                cache.opsForValue().set(c.getId(), token,
                        c.getExpiration().getTime()-System.currentTimeMillis(), TimeUnit.MILLISECONDS);
            }
        } else {
            throw new BusinessException(ErrorCode.OTP_INVALID);
        }
        return TokenResponse.builder()
                .token(jwtUtil.generateToken(c1))
                .userInfo(clientMapper.entityToResponse(c1))
                .build();
    }

    /**
     * {@inheritDoc}
     * Resolves the target avatar image file from the database, associates it with the authenticated
     * client record, and saves the updated client entity.
     *
     * @param fileDto the details of the uploaded file to set as avatar
     * @return the updated file details set as the client's avatar
     * @throws BusinessException if the target avatar file does not exist (ErrorCode.FILE_NOT_FOUND)
     */
    @Override
    public FileDto changeAvatar(FileDto fileDto) {
        File f = fileRepository.findById(fileDto.getId())
                .orElseThrow( () -> new BusinessException(ErrorCode.FILE_NOT_FOUND));
        Client c = clientRepository.findByEmail(SecurityContextHolder.getContext().getAuthentication().getName());
        c.setAvatarFile(f);
        clientRepository.save(c);
        return new FileDto(f);
    }


}
