package org.backend.client.dto.response;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@AllArgsConstructor
public class PlanResponse {
    private Long id;
    private Long price;
    private String name;
    private String timeUnit;
}
