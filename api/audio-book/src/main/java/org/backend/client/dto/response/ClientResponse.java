package org.backend.client.dto.response;


import lombok.Getter;
import lombok.Setter;
import org.backend.client.enums.Tier;
import org.backend.user.dto.response.UserResponse;

/**
 * Response DTO returning Client profile details.
 */
@Getter
@Setter
public class ClientResponse extends UserResponse {

    /**
     * The subscription tier (BASE, PREMIUM).
     */
    private Tier tier;

    /**
     * Total active credit balance.
     */
    private Integer totalCredit;
}
