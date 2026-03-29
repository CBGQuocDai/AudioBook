package org.backend.user.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.Setter;
import org.backend.file.dto.FileDto;
import org.backend.user.enums.RoleEnum;

@Getter
@Setter
@Builder
@AllArgsConstructor
public class UserResponse {
    private long id;
    private String email;
    private String name;
    private FileDto avatarFile;
    private String avatarUrl;
    private RoleEnum role;

    public UserResponse() {
    }
}
