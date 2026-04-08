package org.backend.client.service;

import org.backend.auth.dto.response.TokenResponse;
import org.backend.client.dto.request.ChangeEmailRequest;
import org.backend.client.dto.request.RegisterRequest;
import org.backend.client.dto.response.ClientResponse;
import org.backend.file.dto.FileDto;
import org.springframework.stereotype.Service;

@Service
public interface ClientService {
    void register(RegisterRequest registerRequest);
    ClientResponse me();
    ClientResponse changeName(String name);
    void preChangEmailRequest(String email);
    TokenResponse changeEmail(ChangeEmailRequest req, String token);
    FileDto changeAvatar(FileDto fileDto);
}
