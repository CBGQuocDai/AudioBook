package org.backend.client.mapper;

import lombok.RequiredArgsConstructor;
import org.backend.client.Tier;
import org.backend.client.dto.request.RegisterRequest;
import org.backend.client.dto.response.ClientResponse;
import org.backend.client.entity.Client;
import org.backend.user.enums.RoleEnum;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import software.amazon.awssdk.services.s3.model.GetObjectRequest;
import software.amazon.awssdk.services.s3.presigner.S3Presigner;
import software.amazon.awssdk.services.s3.presigner.model.GetObjectPresignRequest;

import java.time.Duration;

@Component
@RequiredArgsConstructor
public class ClientMapper {

    private final S3Presigner s3Presigner;

    @Value("${aws.bucket-name}")
    private String bucketName;
    public Client registerRequestToEntity(RegisterRequest registerRequest){
        Client client = new Client();
        client.setName(registerRequest.getName());
        client.setEmail(registerRequest.getEmail());
        client.setPassword(registerRequest.getPassword());
        client.setTotalCredit(0);
//        client.setAvatarPath("default.jpg");
        client.setActive(false);
        client.setTier(Tier.BASE);
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
        GetObjectRequest getObjectRequest = GetObjectRequest.builder()
                .bucket(bucketName)
                .key(client.getAvatarPath())
                .build();
        GetObjectPresignRequest req= GetObjectPresignRequest.builder()
                .signatureDuration(Duration.ofMinutes(10))
                .getObjectRequest(getObjectRequest).build();
        String avatarUrl  =s3Presigner.presignGetObject(req).url().toString();
        resp.setAvatarUrl(avatarUrl);
        resp.setTotalCredit(client.getTotalCredit());
        return resp;
    }
}
