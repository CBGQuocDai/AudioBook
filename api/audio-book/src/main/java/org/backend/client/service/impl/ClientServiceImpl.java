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
import org.backend.client.mapper.ClientMapper;
import org.backend.client.repository.ClientRepository;
import org.backend.client.service.ClientService;
import org.backend.common.exception.BusinessException;
import org.backend.common.exception.ErrorCode;
import org.backend.common.util.EmailUtil;
import org.backend.common.util.JwtUtil;
import org.backend.common.util.OtpCodeUtil;
import org.backend.file.entity.File;
import org.backend.file.repository.FileRepository;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.Objects;
import java.util.concurrent.TimeUnit;

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

    @Override
    public ClientResponse me() {
        String email = SecurityContextHolder.getContext().getAuthentication().getName();
        log.info("email: {}", email);
        Client c = clientRepository.findByEmailAndActive(email,true);
        if(Objects.isNull(c)) throw new BusinessException(ErrorCode.USER_NOT_FOUND);
        return clientMapper.entityToResponse(c);
    }

    @Override
    public ClientResponse changeName(String name) {
        String email = SecurityContextHolder.getContext().getAuthentication().getName();
        Client c = clientRepository.findByEmailAndActive(email,true);
        if(Objects.isNull(c)) throw new BusinessException(ErrorCode.USER_NOT_FOUND);
        c.setName(name);
        return clientMapper.entityToResponse(clientRepository.save(c));
    }

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
}
