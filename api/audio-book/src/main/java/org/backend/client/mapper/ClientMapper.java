package org.backend.client.mapper;

import lombok.RequiredArgsConstructor;
import org.backend.client.dto.request.RegisterRequest;
import org.backend.client.dto.response.ClientResponse;
import org.backend.client.entity.Client;
import org.backend.client.enums.Tier;
import org.backend.file.dto.FileDto;
import org.backend.file.entity.File;
import org.backend.user.enums.RoleEnum;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import software.amazon.awssdk.services.s3.presigner.S3Presigner;


@Component
@RequiredArgsConstructor
public class ClientMapper {


    public Client registerRequestToEntity(RegisterRequest registerRequest){
        Client client = new Client();
        client.setName(registerRequest.getName());
        client.setEmail(registerRequest.getEmail());
        client.setPassword(registerRequest.getPassword());
        client.setTotalCredit(0);

        client.setActive(false);
        client.setRole(RoleEnum.USER);
        return client;
    }

    public ClientResponse entityToResponse(Client client){
        ClientResponse resp = new ClientResponse();
        resp.setEmail(client.getEmail());
        resp.setName(client.getName());
        resp.setRole(client.getRole());
        resp.setId(client.getId());
        resp.setAvatarFile(client.getAvatarFile() == null ? null : new FileDto(client.getAvatarFile()));
        resp.setTotalCredit(client.getTotalCredit());
        return resp;
    }
}
