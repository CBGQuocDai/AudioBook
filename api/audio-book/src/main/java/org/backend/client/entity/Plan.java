package org.backend.client.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import org.backend.client.enums.TimeUnit;


@Entity
@Getter
@Setter
public class Plan {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)

    private long id;
    private Long price;
    private String name;
    @Enumerated(EnumType.STRING)
    private TimeUnit timeUnit;
}
