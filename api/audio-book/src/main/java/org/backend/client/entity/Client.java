package org.backend.client.entity;

import jakarta.persistence.*;
import lombok.*;
import lombok.experimental.FieldNameConstants;
import org.backend.user.entity.User;

import java.util.List;

@Entity
@Table(name = "client")
@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
@FieldNameConstants
@PrimaryKeyJoinColumn(name = "user_id")
public class Client extends User {

    @Column(name = "total_credit")
    private Integer totalCredit;

    @OneToMany(mappedBy = "client")
    private List<Subscription> subscriptions;

    @OneToMany(mappedBy = "client")
    private List<CreditTransaction> creditTransactions;
}
