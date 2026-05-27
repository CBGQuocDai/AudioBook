package org.backend.client.dto.request;

import lombok.Getter;
import lombok.Setter;

/**
 * Request DTO containing details required to register a new Client user.
 */
@Getter
@Setter
public class RegisterRequest {
    /**
     * The full name of the registering client.
     */
    private String name;

    /**
     * The unique email address for registration.
     */
    private String email;

    /**
     * The password selected by the client.
     */
    private String password;

}
