package org.backend.user.dto.request;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;
import org.backend.user.enums.RoleEnum;

@Getter
@Setter
public class UpdateUserRequest {
    @NotBlank(message = "Name is required")
    private String name;

    @Email(message = "Email is not valid")
    @NotBlank(message = "Email is required")
    private String email;

    private String password;

    @NotNull(message = "Avatar file id is required")
    private Long avatarFileId;

    private RoleEnum role;
}
