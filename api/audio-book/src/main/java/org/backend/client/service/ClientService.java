package org.backend.client.service;

import org.backend.client.dto.request.RegisterRequest;
import org.springframework.stereotype.Service;

@Service
public interface ClientService {
    void register(RegisterRequest registerRequest);
}
