package org.backend.common.dto.request;

import com.fasterxml.jackson.annotation.JsonAlias;
import lombok.Getter;
import lombok.Setter;
import org.backend.common.util.Constant;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.util.StringUtils;

@Getter
@Setter
public class CommonPageableRequest {

    protected static final String CREATED_AT = "createdAt";
    protected static final String UPDATED_AT = "updatedAt";
    protected static final String CREATED_BY = "createdBy";
    protected static final String LAST_MODIFIED_BY = "lastModifiedBy";

    @JsonAlias({"pageNumber"})
    protected int page = 0;

    @JsonAlias({"size", "pageSize"})
    protected int limit = 20;

    // Optional alias to support request parameter name `pageNumber`.
    protected Integer pageNumber;

    // Optional alias to support request parameter name `orderBy`.
    protected String orderBy;

    protected String sortBy;
    protected String sortOrder;

    public int getPage() {
        return pageNumber != null ? Math.max(pageNumber, 0) : Math.max(page, 0);
    }

    public int getLimit() {
        return limit <= 0 ? 20 : limit;
    }

    protected String getSortBy() {
        String normalizedSortBy = StringUtils.hasText(sortBy) ? sortBy : orderBy;
        normalizedSortBy = StringUtils.hasText(normalizedSortBy) ? normalizedSortBy : "id";
        if (UPDATED_AT.equals(normalizedSortBy)) {
            return "lastModifiedAt";
        }
        return normalizedSortBy;
    }

    protected String getSortOrder() {
        return StringUtils.hasText(sortOrder) ? sortOrder : Constant.SORT_DESC;
    }

    public Pageable toPageable() {
        if (!StringUtils.hasText(getSortBy())) {
            return PageRequest.of(getPage(), getLimit());
        }

        Sort.Order order = Constant.SORT_ASC.equalsIgnoreCase(getSortOrder())
                ? Sort.Order.asc(getSortBy())
                : Sort.Order.desc(getSortBy());

        return PageRequest.of(getPage(), getLimit(), Sort.by(order));
    }
}

