package org.backend.user.entity;

import jakarta.persistence.*;
import lombok.*;
import lombok.experimental.FieldNameConstants;

@Entity
@Table(name = "admin")
@Getter
@Setter
@NoArgsConstructor
@FieldNameConstants
@PrimaryKeyJoinColumn(name = "user_id")
public class Admin extends User {
}
