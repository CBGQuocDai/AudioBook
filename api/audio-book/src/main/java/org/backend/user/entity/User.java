package org.backend.user.entity;

import jakarta.persistence.*;
import lombok.*;
import lombok.experimental.FieldNameConstants;
import org.backend.common.entity.SoftDeleteEntity;
import org.backend.file.entity.File;
import org.backend.user.enums.RoleEnum;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;

import java.util.Collection;
import java.util.List;

/**
 * Entity representation of registered users.
 * Maps security data models and handles {@link UserDetails} integration parameters.
 */
@Entity
@Table(name = "users")
@Inheritance(strategy = InheritanceType.JOINED)
@Getter
@Setter
@Builder
@AllArgsConstructor
@NoArgsConstructor
@FieldNameConstants
public class User extends SoftDeleteEntity implements UserDetails {

    /**
     * Unique surrogate primary database identifier.
     */
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /**
     * Encrypted credential string password.
     */
    @Column(name = "password", nullable = false)
    private String password;

    /**
     * Customer name display.
     */
    @Column(name = "name", nullable = false)
    private String name;

    /**
     * Contact email acting as unique login user identifier.
     */
    @Column(name = "email", nullable = false)
    private String email;
//
//    @Column(name = "wallet")
//    private String wallet;

    /**
     * Role enum defining standard system access permissions.
     */
    @Enumerated(EnumType.STRING)
    @Column(name = "role", nullable = false)
    private RoleEnum role;

    /**
     * Many-to-one mapping pointing to target user avatar file asset.
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "avatar_file_id")
    private File avatarFile;

    /**
     * Validation flag mapping account email verification state.
     */
    @Column(name = "active")
    private Boolean active;

    /**
     * Resolves the Spring Security authorities list matching the User role configuration.
     *
     * @return collection of granted security authorities
     */
    @Override
    public Collection<? extends GrantedAuthority> getAuthorities() {
        return List.of(new SimpleGrantedAuthority("ROLE_"+role.name()));
    }

    /**
     * Resolves standard username value mapping back to email properties.
     *
     * @return unique email string parameter
     */
    @Override
    public String getUsername() {
        return this.email;
    }

    /**
     * Asserts if authentication validation is non-expired.
     *
     * @return constant validity status
     */
    @Override
    public boolean isAccountNonExpired() {
        return false;
    }

    /**
     * Asserts if account login is non-locked.
     *
     * @return constant locking status
     */
    @Override
    public boolean isAccountNonLocked() {
        return false;
    }

    /**
     * Asserts if token authentication keys are active.
     *
     * @return credential validity state
     */
    @Override
    public boolean isCredentialsNonExpired() {
        return false;
    }

    /**
     * Asserts if account is fully configured and enabled.
     *
     * @return enabling condition
     */
    @Override
    public boolean isEnabled() {
        return false;
    }
}

