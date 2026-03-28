package org.backend.client.controller;


import lombok.RequiredArgsConstructor;
import org.backend.client.dto.request.RegisterRequest;
import org.backend.client.service.ClientService;
import org.backend.common.response.ApiResponse;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequiredArgsConstructor
@RequestMapping("/client")
@Validated
public class ClientController {

    private final ClientService clientService;

    @PostMapping("/register")
    public ApiResponse<Void> register(@RequestBody RegisterRequest req) {
        clientService.register(req);
        return ApiResponse.<Void>builder().build();
    }

}

