package org.backend.client.dto.request;


import lombok.Getter;
import lombok.Setter;

/**
 * Request DTO containing the proposed email for starting the email verification change process.
 */
@Getter
@Setter
public class PreChangeEmailRequest {
    /**
     * The new target email address.
     */
    private String newEmail;
}
