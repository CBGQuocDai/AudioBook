package org.backend.user.service;

import org.backend.user.dto.response.UserResponse;
import org.backend.user.entity.User;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.stereotype.Service;

/**
 * Service interface defining user management logic, account discovery, and security profile mappings.
 */
@Service
public interface UserService extends UserDetailsService {

    /**
     * Resolves the profile representation details of the currently authenticated active session.
     *
     * @return UserResponse structure with personal account details
     */
    UserResponse getMe();

    /**
     * Retrieves the raw User entity representation of the current logged-in session.
     *
     * @return the authentic User entity model
     */
    User getCurrentLoginUser();
}
