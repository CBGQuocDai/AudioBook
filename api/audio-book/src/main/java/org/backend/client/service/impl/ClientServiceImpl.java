package org.backend.client.service.impl;


import lombok.RequiredArgsConstructor;
import org.backend.client.dto.request.RegisterRequest;
import org.backend.client.entity.Client;
import org.backend.client.mapper.ClientMapper;
import org.backend.client.repository.ClientRepository;
import org.backend.client.service.ClientService;
import org.backend.common.exception.BusinessException;
import org.backend.common.exception.ErrorCode;
import org.backend.common.util.OtpCodeUtil;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.Objects;
import java.util.concurrent.TimeUnit;

@Service
@RequiredArgsConstructor
public class ClientServiceImpl implements ClientService {

    private final ClientRepository clientRepository;
    private final RedisTemplate<String, Object> cache;
    private final ClientMapper clientMapper;
    private final PasswordEncoder passwordEncoder;
    @Override
    public void register(RegisterRequest registerRequest) {
        Client c = clientMapper.registerRequestToEntity(registerRequest);
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
//        send email here

        cache.opsForValue().set(c.getEmail(), code, 5, TimeUnit.MINUTES);
    }
}
