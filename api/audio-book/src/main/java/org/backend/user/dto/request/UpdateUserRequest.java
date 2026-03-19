package org.backend.user.dto.request;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
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

    private RoleEnum role;
}

