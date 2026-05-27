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
import org.backend.file.dto.FileDto;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

/**
 * Controller to handle client profile operations like registration, fetching profile info,
 * changing name, email update verification flows, and updating avatars.
 */
@RestController
@RequiredArgsConstructor
@RequestMapping("/client")
@Validated
@Slf4j
public class ClientController {

    private final ClientService clientService;

    /**
     * Registers a new client user.
     *
     * @param req The register details request.
     * @return ApiResponse indicating successful registration trigger.
     */
    @PostMapping("/register")
    public ApiResponse<Void> register(@RequestBody RegisterRequest req) {
        clientService.register(req);
        return ApiResponse.<Void>builder().build();
    }

    /**
     * Retrieves current logged in client profile details.
     *
     * @return ApiResponse containing the ClientResponse.
     */
    @GetMapping("/me")
    public ApiResponse<ClientResponse> me() {
        return ApiResponse.<ClientResponse>builder()
                .data(clientService.me())
                .build();
    }

    /**
     * Updates the name of the currently authenticated client.
     *
     * @param req Request containing the new name.
     * @return ApiResponse containing updated ClientResponse.
     */
    @PutMapping("/change-name")
    public ApiResponse<ClientResponse> changeName(@RequestBody ChangeNameRequest req)  {
        return ApiResponse.<ClientResponse>builder()
                .data(clientService.changeName(req.getName()))
                .build();
    }

    /**
     * Triggers a verification email containing OTP/verification token to pre-approve email change.
     *
     * @param req Request containing the new target email.
     * @return ApiResponse with empty payload signifying successful process trigger.
     */
    @PostMapping("/email/pre-change")
    public ApiResponse<Void> changePassword(@RequestBody PreChangeEmailRequest req )  {
        clientService.preChangEmailRequest(req.getNewEmail());
        return ApiResponse.<Void>builder().build();
    }

    /**
     * Confirms the change of client email by providing a valid code/token.
     *
     * @param req Request containing the new email and verification code/token.
     * @param token Authentication Bearer header.
     * @return ApiResponse containing new JWT token.
     */
    @PutMapping("/email/change")
    public ApiResponse<TokenResponse> changeEmail(
            @RequestBody ChangeEmailRequest req,
            @RequestHeader("Authorization") String token){
        log.info("change email with token: {}", req.getNewEmail());
        return ApiResponse.<TokenResponse>builder()
                .data(clientService.changeEmail(req,token.substring(7)))
                .build();
    }

    /**
     * Updates the avatar file of the authenticated client.
     *
     * @param fileDto DTO representing the new avatar file.
     * @return ApiResponse containing updated avatar details.
     */
    @PutMapping("/avatar/change")
    public ApiResponse<FileDto> changeAvatar (@RequestBody FileDto fileDto) {
        return ApiResponse.<FileDto>builder()
                .data(clientService.changeAvatar(fileDto))
                .build();
    }

}

