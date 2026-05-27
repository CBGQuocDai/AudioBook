package org.backend.client.service;

import org.backend.auth.dto.response.TokenResponse;
import org.backend.client.dto.request.ChangeEmailRequest;
import org.backend.client.dto.request.RegisterRequest;
import org.backend.client.dto.response.ClientResponse;
import org.backend.common.exception.BusinessException;
import org.backend.file.dto.FileDto;
import org.springframework.stereotype.Service;

/**
 * Service interface for managing client accounts, authentication details, and profiles.
 * Provides operations for registration, profile retrieval, name updates, email changes, and avatar updates.
 */
@Service
public interface ClientService {
    /**
     * Registers a new client account and sends an email verification OTP code.
     *
     * @param registerRequest the registration details of the new client
     * @throws BusinessException if the email already exists and is active, or default avatar file is not found
     */
    void register(RegisterRequest registerRequest);

    /**
     * Retrieves the profile information of the currently authenticated client.
     * Determines client subscription status and active tier (BASE or PREMIUM).
     *
     * @return the profile response containing authenticated client details and tier status
     * @throws BusinessException if the authenticated user is not found in the database
     */
    ClientResponse me();

    /**
     * Updates the name of the currently authenticated client.
     *
     * @param name the new name for the client
     * @return the updated client profile information
     * @throws BusinessException if the authenticated user is not found in the database
     */
    ClientResponse changeName(String name);

    /**
     * Prepares and initiates a request to change the client's email address.
     * Generates and sends a verification OTP to the target email if it is not already taken.
     *
     * @param email the new email address to be verified
     * @throws BusinessException if the new email is already registered and active
     */
    void preChangEmailRequest(String email);

    /**
     * Completes the email update process by verifying the OTP for the new email address.
     * Updates the email in the repository, revokes the old JWT token, and returns a new authentication token.
     *
     * @param req the details containing the new email and the verification OTP code
     * @param token the current active JWT token of the authenticated client
     * @return a new token response containing the updated token and user information
     * @throws BusinessException if the OTP is invalid or expired
     */
    TokenResponse changeEmail(ChangeEmailRequest req, String token);

    /**
     * Updates the avatar image of the currently authenticated client.
     *
     * @param fileDto the details of the uploaded file to set as avatar
     * @return the updated file details set as the client's avatar
     * @throws BusinessException if the target avatar file does not exist
     */
    FileDto changeAvatar(FileDto fileDto);
}
