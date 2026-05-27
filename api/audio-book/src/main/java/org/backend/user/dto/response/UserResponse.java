package org.backend.user.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.Setter;
import org.backend.file.dto.FileDto;
import org.backend.user.enums.RoleEnum;

/**
 * DTO data structure wrapping user profile details for response outputs.
 */
@Getter
@Setter
@Builder
@AllArgsConstructor
public class UserResponse {

    /**
     * Unique client database ID.
     */
    private long id;

    /**
     * Client email address.
     */
    private String email;

    /**
     * Client public name.
     */
    private String name;

    /**
     * Avatar image file details.
     */
    private FileDto avatarFile;

    /**
     * Computed public URL pointing directly to target avatar asset.
     */
    private String avatarUrl;

    /**
     * Access level role.
     */
    private RoleEnum role;

    /**
     * Verification/activity status.
     */
    private Boolean active;

    /**
     * Empty constructor.
     */
    public UserResponse() {
    }
}
