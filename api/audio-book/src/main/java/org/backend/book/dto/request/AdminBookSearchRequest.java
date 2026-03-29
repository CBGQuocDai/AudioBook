package org.backend.book.dto.request;

import lombok.Getter;
import lombok.Setter;
import org.backend.common.dto.request.CommonPageableRequest;

@Getter
@Setter
public class AdminBookSearchRequest extends CommonPageableRequest {
    private String keyword;
}

