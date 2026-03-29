package org.backend.client.dto.response;


import lombok.Getter;
import lombok.Setter;
import org.backend.client.Tier;
import org.backend.user.dto.response.UserResponse;

@Getter
@Setter
public class ClientResponse extends UserResponse {

    private Tier tier;
    private Integer totalCredit;
}
