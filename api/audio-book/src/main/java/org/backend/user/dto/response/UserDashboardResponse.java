package org.backend.user.dto.response;

import org.backend.common.dto.response.TimeSeriesPointResponse;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.Setter;

import java.util.List;

@Getter
@Setter
@Builder
@AllArgsConstructor
public class UserDashboardResponse {
    private long totalUsers;
    private long activeUsers;
    private long inactiveUsers;
    private long usersThisMonth;
    private long usersLastMonth;
    private double growthPercent;
    private String growthDirection;
    private List<TimeSeriesPointResponse> dailyRegistrations;
    private List<TimeSeriesPointResponse> monthlyRegistrations;
}


