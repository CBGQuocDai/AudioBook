package org.backend.user.dto.request;

import lombok.Getter;
import lombok.Setter;
import org.backend.common.dto.request.CommonPageableRequest;

@Getter
@Setter
public class AdminUserSearchRequest extends CommonPageableRequest {
    private String keyword;
}

