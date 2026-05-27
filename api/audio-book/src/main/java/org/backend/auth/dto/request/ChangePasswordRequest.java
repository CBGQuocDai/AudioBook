package org.backend.auth.dto.request;


import lombok.Getter;
import lombok.Setter;

/**
 * Request payload for changing the user's password while logged in.
 */
@Getter
@Setter
public class ChangePasswordRequest {
    /**
     * The user's current password.
     */
    private String oldPassword;
    /**
     * The new password to replace the current password.
     */
    private String newPassword;
}
