package org.backend.client.entity;


import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import org.backend.client.enums.Status;

import java.time.LocalDate;

@Entity
@Getter
@Setter
public class Subscription {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    private LocalDate startAt;
    @Enumerated(EnumType.STRING)
    private Status status;
    @ManyToOne
    @JoinColumn(name= "client_id")
    private Client client;
    @ManyToOne
    @JoinColumn(name="plan_id")
    private Plan plan;
}
