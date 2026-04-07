package org.backend.user.service.impl;

import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import org.backend.common.dto.response.TimeSeriesPointResponse;
import org.backend.common.exception.BusinessException;
import org.backend.common.exception.ErrorCode;
import org.backend.file.entity.File;
import org.backend.file.enums.FileType;
import org.backend.file.repository.FileRepository;
import org.backend.user.dto.request.AdminUserSearchRequest;
import org.backend.user.dto.request.CreateUserRequest;
import org.backend.user.dto.request.UpdateUserRequest;
import org.backend.user.dto.request.UpdateUserStatusRequest;
import org.backend.user.dto.response.UserDashboardResponse;
import org.backend.user.dto.response.UserResponse;
import org.backend.user.entity.User;
import org.backend.user.enums.RoleEnum;
import org.backend.user.mapper.UserMapper;
import org.backend.user.repository.UserRepository;
import org.backend.user.service.UserService;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

import java.time.LocalDateTime;
import java.time.YearMonth;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;

@Service
@RequiredArgsConstructor
public class UserServiceImpl implements UserService {
    private static final ZoneId DASHBOARD_ZONE = ZoneId.of("Asia/Ho_Chi_Minh");
    private static final DateTimeFormatter DAY_LABEL_FORMATTER = DateTimeFormatter.ofPattern("dd/MM");
    private static final DateTimeFormatter MONTH_LABEL_FORMATTER = DateTimeFormatter.ofPattern("MM/yyyy");

    private final UserRepository userRepository;
    private final FileRepository fileRepository;
    private final UserMapper userMapper;
    private final PasswordEncoder passwordEncoder;

    @Override
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
        return userRepository.findByEmail(username);
    }

    @Override
    public UserResponse getMe() {
        User user = (User) SecurityContextHolder.getContext().getAuthentication().getPrincipal();

        return userMapper.entityToResponse(user);
    }

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

    @Override
    public List<UserResponse> getAllUsers(HttpServletRequest request) {
        return userRepository.findAll().stream()
                .map(userMapper::entityToResponse)
                .toList();
    }

    @Override
    public UserDashboardResponse getDashboard() {
        LocalDate today = LocalDate.now(DASHBOARD_ZONE);
        YearMonth currentMonth = YearMonth.from(today);
        YearMonth previousMonth = currentMonth.minusMonths(1);

        long totalUsers = userRepository.count();
        long activeUsers = userRepository.countByActiveTrue();
        long inactiveUsers = userRepository.countByActiveFalse();
        long usersThisMonth = countUsersByMonth(currentMonth);
        long usersLastMonth = countUsersByMonth(previousMonth);

        List<TimeSeriesPointResponse> dailyRegistrations = buildDailyRegistrations(today);
        List<TimeSeriesPointResponse> monthlyRegistrations = buildMonthlyRegistrations(currentMonth);

        double growthPercent;
        String growthDirection;
        if (usersLastMonth == 0) {
            if (usersThisMonth == 0) {
                growthPercent = 0.0;
                growthDirection = "FLAT";
            } else {
                growthPercent = 100.0;
                growthDirection = "UP";
            }
        } else {
            growthPercent = ((double) (usersThisMonth - usersLastMonth) / usersLastMonth) * 100.0;
            if (growthPercent > 0) {
                growthDirection = "UP";
            } else if (growthPercent < 0) {
                growthDirection = "DOWN";
            } else {
                growthDirection = "FLAT";
            }
        }

        return UserDashboardResponse.builder()
                .totalUsers(totalUsers)
                .activeUsers(activeUsers)
                .inactiveUsers(inactiveUsers)
                .usersThisMonth(usersThisMonth)
                .usersLastMonth(usersLastMonth)
                .growthPercent(growthPercent)
                .growthDirection(growthDirection)
                .dailyRegistrations(dailyRegistrations)
                .monthlyRegistrations(monthlyRegistrations)
                .build();
    }

    private long countUsersByMonth(YearMonth month) {
        LocalDateTime start = month.atDay(1).atStartOfDay();
        LocalDateTime end = month.plusMonths(1).atDay(1).atStartOfDay();
        return userRepository.countByCreatedAtGreaterThanEqualAndCreatedAtLessThan(start, end);
    }

    private List<TimeSeriesPointResponse> buildDailyRegistrations(LocalDate today) {
        List<TimeSeriesPointResponse> result = new ArrayList<>();
        for (int i = 6; i >= 0; i--) {
            LocalDate day = today.minusDays(i);
            LocalDateTime start = day.atStartOfDay();
            LocalDateTime end = day.plusDays(1).atStartOfDay();
            result.add(TimeSeriesPointResponse.builder()
                    .label(day.format(DAY_LABEL_FORMATTER))
                    .value(userRepository.countByCreatedAtGreaterThanEqualAndCreatedAtLessThan(start, end))
                    .build());
        }
        return result;
    }

    private List<TimeSeriesPointResponse> buildMonthlyRegistrations(YearMonth currentMonth) {
        List<TimeSeriesPointResponse> result = new ArrayList<>();
        for (int i = 11; i >= 0; i--) {
            YearMonth month = currentMonth.minusMonths(i);
            result.add(TimeSeriesPointResponse.builder()
                    .label(month.format(MONTH_LABEL_FORMATTER))
                    .value(countUsersByMonth(month))
                    .build());
        }
        return result;
    }

    @Override
    public Page<UserResponse> searchUsers(AdminUserSearchRequest searchRequest, HttpServletRequest request) {
        Pageable pageable = searchRequest.toPageable();
        String keyword = searchRequest.getKeyword();

        Page<User> userPage = StringUtils.hasText(keyword)
                ? userRepository.searchByKeyword(keyword.trim(), pageable)
                : userRepository.findAll(pageable);

        return userPage.map(userMapper::entityToResponse);
    }

    @Override
    public UserResponse getUserById(Long id, HttpServletRequest request) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new BusinessException(ErrorCode.USER_NOT_FOUND));
        return userMapper.entityToResponse(user);
    }

    @Override
    public UserResponse createUser(CreateUserRequest createUserRequest, HttpServletRequest request) {
        if (userRepository.existsByEmail(createUserRequest.getEmail())) {
            throw new BusinessException(ErrorCode.USER_EXIST);
        }

        File avatarFile = fileRepository.findById(createUserRequest.getAvatarFileId())
                .orElseThrow(() -> new BusinessException(ErrorCode.FILE_NOT_FOUND));
        if (!FileType.isImageFile(FileType.fromString(avatarFile.getType()))) {
            throw new BusinessException(ErrorCode.FILE_NOT_IMAGE);
        }

        RoleEnum role = createUserRequest.getRole() == null ? RoleEnum.USER : createUserRequest.getRole();
        User user = User.builder()
                .name(createUserRequest.getName())
                .email(createUserRequest.getEmail())
                .password(passwordEncoder.encode(createUserRequest.getPassword()))
                .avatarFile(avatarFile)
                .role(role)
                .active(true)
                .build();

        User savedUser = userRepository.save(user);
        return userMapper.entityToResponse(savedUser);
    }

    @Override
    public UserResponse updateUser(Long id, UpdateUserRequest updateUserRequest, HttpServletRequest request) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new BusinessException(ErrorCode.USER_NOT_FOUND));

        String email = updateUserRequest.getEmail().trim();
        User existingUser = userRepository.findByEmail(email);
        if (existingUser != null && !existingUser.getId().equals(id)) {
            throw new BusinessException(ErrorCode.USER_EXIST);
        }

        File avatarFile = fileRepository.findById(updateUserRequest.getAvatarFileId())
                .orElseThrow(() -> new BusinessException(ErrorCode.FILE_NOT_FOUND));
        if (!FileType.isImageFile(FileType.fromString(avatarFile.getType()))) {
            throw new BusinessException(ErrorCode.FILE_NOT_IMAGE);
        }

        user.setName(updateUserRequest.getName().trim());
        user.setEmail(email);
        user.setAvatarFile(avatarFile);
        user.setRole(updateUserRequest.getRole() == null ? user.getRole() : updateUserRequest.getRole());
        user.setActive(updateUserRequest.getActive() == null ? user.getActive() : updateUserRequest.getActive());

        if (StringUtils.hasText(updateUserRequest.getPassword())) {
            user.setPassword(passwordEncoder.encode(updateUserRequest.getPassword()));
        }

        User savedUser = userRepository.save(user);
        return userMapper.entityToResponse(savedUser);
    }

    @Override
    public void updateUserStatus(Long id, UpdateUserStatusRequest updateUserStatusRequest) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new BusinessException(ErrorCode.USER_NOT_FOUND));

        user.setActive(updateUserStatusRequest.getActive());
        userRepository.save(user);
    }

    @Override
    public void deleteUser(Long id) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new BusinessException(ErrorCode.USER_NOT_FOUND));
        userRepository.delete(user);
    }
}
