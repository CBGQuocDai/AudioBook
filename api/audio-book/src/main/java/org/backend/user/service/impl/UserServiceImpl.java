package org.backend.user.service.impl;

import lombok.RequiredArgsConstructor;
import org.backend.common.exception.BusinessException;
import org.backend.common.exception.ErrorCode;
import org.backend.user.dto.response.UserResponse;
import org.backend.user.entity.User;
import org.backend.user.mapper.UserMapper;
import org.backend.user.repository.UserRepository;
import org.backend.user.service.UserService;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

/**
 * Concrete implementation class implementing User management, profiles retrieval, and security context mappings.
 */
@Service
@RequiredArgsConstructor
public class UserServiceImpl implements UserService {

    /**
     * Data layer database user manager.
     */
    private final UserRepository userRepository;

    /**
     * DTO mapping translator.
     */
    private final UserMapper userMapper;

    /**
     * Standard authentication adapter resolving User details using incoming email identifiers.
     * Used internally by standard Security processes.
     *
     * @param username targeted search email identifier
     * @return UserDetails profile matches
     * @throws UsernameNotFoundException when no matching account profile is located
     */
    @Override
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
        return userRepository.findByEmail(username);
    }

    /**
     * Extract active session user context and translates back matching profile responses.
     *
     * @return active session user response details
     */
    @Override
    public UserResponse getMe() {
        User user = (User) SecurityContextHolder.getContext().getAuthentication().getPrincipal();

        return userMapper.entityToResponse(user);
    }

    /**
     * Resolves currently authenticated sessions or throws security exception constraints.
     * Performs sanity checks over credentials identity context.
     *
     * @return the authentic User entity model
     * @throws BusinessException (UNAUTHORIZED) if request has invalid or empty authentication context
     * @throws BusinessException (USER_NOT_FOUND) if matched session identity holds non-existing credentials
     */
    @Override
    public User getCurrentLoginUser() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();

        if (authentication == null || !authentication.isAuthenticated()) {
            throw new BusinessException(ErrorCode.UNAUTHORIZED);
        }

        Object principal = authentication.getPrincipal();
        if (principal == null || "anonymousUser".equals(principal)) {
            throw new BusinessException(ErrorCode.UNAUTHORIZED);
        }

        String email = authentication.getName();
        if (email == null || email.isBlank()) {
            throw new BusinessException(ErrorCode.UNAUTHORIZED);
        }

        User user = userRepository.findByEmail(email);
        if (user == null) {
            throw new BusinessException(ErrorCode.USER_NOT_FOUND);
        }
        return user;
    }
}
