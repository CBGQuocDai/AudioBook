package org.backend.book.dto.request;

import org.backend.common.dto.request.CommonPageableRequest;

public class ClientBookSearchRequest extends CommonPageableRequest {
    private String keyword;
}
