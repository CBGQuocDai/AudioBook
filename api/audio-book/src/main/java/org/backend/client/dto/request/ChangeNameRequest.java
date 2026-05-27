package org.backend.client.dto.request;


import lombok.Getter;
import lombok.Setter;

/**
 * Request DTO to update the client's display name.
 */
@Getter
@Setter
public class ChangeNameRequest {
    /**
     * The new display name.
     */
    private String name;
}
