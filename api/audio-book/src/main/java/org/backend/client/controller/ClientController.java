package org.backend.client.controller;


import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.backend.auth.dto.request.OtpRequest;
import org.backend.auth.dto.response.TokenResponse;
import org.backend.client.dto.request.ChangeEmailRequest;
import org.backend.client.dto.request.ChangeNameRequest;
import org.backend.client.dto.request.PreChangeEmailRequest;
import org.backend.client.dto.request.RegisterRequest;
import org.backend.client.dto.response.ClientResponse;
import org.backend.client.service.ClientService;
import org.backend.common.response.ApiResponse;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

@RestController
@RequiredArgsConstructor
@RequestMapping("/client")
@Validated
@Slf4j
public class ClientController {

    private final ClientService clientService;

    @PostMapping("/register")
    public ApiResponse<Void> register(@RequestBody RegisterRequest req) {
        clientService.register(req);
        return ApiResponse.<Void>builder().build();
    }

    @GetMapping("/me")
    public ApiResponse<ClientResponse> me() {
        return ApiResponse.<ClientResponse>builder()
                .data(clientService.me())
                .build();
    }

    @PutMapping("/change-name")
    public ApiResponse<ClientResponse> changeName(@RequestBody ChangeNameRequest req)  {
        return ApiResponse.<ClientResponse>builder()
                .data(clientService.changeName(req.getName()))
                .build();
    }

    @PostMapping("/email/pre-change")
    public ApiResponse<Void> changePassword(@RequestBody PreChangeEmailRequest req )  {
        clientService.preChangEmailRequest(req.getNewEmail());
        return ApiResponse.<Void>builder().build();
    }
    @PutMapping("/email/change")
    public ApiResponse<TokenResponse> changeEmail(
            @RequestBody ChangeEmailRequest req,
            @RequestHeader("Authorization") String token){
        log.info("change email with token: {}", req.getNewEmail());
        return ApiResponse.<TokenResponse>builder()
                .data(clientService.changeEmail(req,token.substring(7)))
                .build();
    }

}

