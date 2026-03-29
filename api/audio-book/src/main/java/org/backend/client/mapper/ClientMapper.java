package org.backend.client.mapper;

import org.backend.client.dto.request.RegisterRequest;
import org.backend.client.dto.response.ClientResponse;
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

    public ClientResponse entityToResponse(Client client){
        ClientResponse resp = new ClientResponse();
        resp.setTier(client.getTier());
        resp.setEmail(client.getEmail());
        resp.setName(client.getName());
        resp.setRole(client.getRole());
        resp.setId(client.getId());
        resp.setAvatarUrl(
                client.getAvatarPath()
        );
        resp.setTotalCredit(client.getTotalCredit());
        return resp;
    }
}
