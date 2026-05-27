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

/**
 * Component class to map client-related objects from DTOs to Entities and vice-versa.
 */
@Component
@RequiredArgsConstructor
public class ClientMapper {

    /**
     * Maps a RegisterRequest DTO to a Client entity.
     * Sets default properties like totalCredit to 0, active status to false, and role to USER.
     *
     * @param registerRequest The request containing client registration details.
     * @return The populated Client entity.
     */
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

    /**
     * Maps a Client entity to a ClientResponse DTO.
     * Converts properties like email, name, role, totalCredit, and files.
     *
     * @param client The Client entity.
     * @return The populated ClientResponse DTO.
     */
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
