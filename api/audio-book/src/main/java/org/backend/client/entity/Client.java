package org.backend.client.entity;

import jakarta.persistence.*;
import lombok.*;
import lombok.experimental.FieldNameConstants;
import org.backend.user.entity.User;

import java.util.List;

/**
 * Entity representing a Client, which extends the User class.
 * Stores details related to client-specific actions like credits and subscription.
 */
@Entity
@Table(name = "client")
@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
@FieldNameConstants
@PrimaryKeyJoinColumn(name = "user_id")
public class Client extends User {

    /**
     * Total amount of credit the client currently possesses.
     */
    @Column(name = "total_credit")
    private Integer totalCredit;

    /**
     * List of subscription history items for the client.
     */
    @OneToMany(mappedBy = "client")
    private List<Subscription> subscriptions;

    /**
     * List of credit transactions made by the client.
     */
    @OneToMany(mappedBy = "client")
    private List<CreditTransaction> creditTransactions;
}
