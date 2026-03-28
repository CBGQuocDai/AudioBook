package org.backend.client.mapper;

import org.backend.client.dto.request.RegisterRequest;
import org.backend.client.entity.Client;
import org.backend.user.enums.RoleEnum;
import org.springframework.stereotype.Component;

@Component
public class ClientMapper {

    public Client registerRequestToEntity(RegisterRequest registerRequest){
        Client client = new Client();
        client.setName(registerRequest.getName());
        client.setEmail(registerRequest.getEmail());
        client.setPassword(registerRequest.getPassword());
        client.setTotalCredit(0);
//        client.setAvatarPath("default.jpg");
        client.setActive(false);
        client.setRole(RoleEnum.USER);
        return client;
    }
}
