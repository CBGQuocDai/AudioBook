package org.backend.client.service.impl;

import lombok.RequiredArgsConstructor;
import org.backend.client.dto.request.UpPremiumRequest;
import org.backend.client.dto.response.SubscriptionHistoryItemResponse;
import org.backend.client.dto.response.SubscriptionInfoResponse;
import org.backend.client.entity.Client;
import org.backend.client.entity.Plan;
import org.backend.client.entity.Subscription;
import org.backend.client.enums.Status;
import org.backend.client.enums.TimeUnit;
import org.backend.client.repository.ClientRepository;
import org.backend.client.repository.PlanRepository;
import org.backend.client.repository.SubscriptionRepository;
import org.backend.client.service.SubscriptionService;
import org.backend.common.exception.BusinessException;
import org.backend.common.exception.ErrorCode;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.List;
import java.util.Objects;

@Service
@RequiredArgsConstructor
public class SubscriptionServiceImpl implements SubscriptionService {
    private final ClientRepository clientRepository;
    private final SubscriptionRepository subscriptionRepository;
    private final PlanRepository planRepository;

    @Override
    public void subscribe(UpPremiumRequest req) {
        String email = SecurityContextHolder.getContext().getAuthentication().getName();
        Client c = clientRepository.findByEmailAndActive(email, true);
        if (Objects.isNull(c)) throw new BusinessException(ErrorCode.USER_NOT_FOUND);

        Subscription s = new Subscription();
        s.setClient(c);
        Plan p = planRepository.getReferenceById(req.getPlanId());
        s.setPlan(p);
        s.setStatus(Status.ACTIVE);
        s.setStartAt(LocalDate.now());
        subscriptionRepository.save(s);

    }

    @Override
    public SubscriptionInfoResponse getSubscriptionInfo() {
        String email = SecurityContextHolder.getContext().getAuthentication().getName();
        Client c = clientRepository.findByEmailAndActive(email, true);
        if (Objects.isNull(c)) throw new BusinessException(ErrorCode.USER_NOT_FOUND);

        List<Subscription> subscriptions = subscriptionRepository.findHistoryByClientId(c.getId());
        if (subscriptions.isEmpty()) {
            return SubscriptionInfoResponse.builder()
                    .status("CHUA_DANG_KY")
                    .billingHistory(List.of())
                    .build();
        }

        Subscription current = subscriptionRepository.findLatestActiveValidSubscription(c.getId())
                .orElse(subscriptions.get(0));

        List<SubscriptionHistoryItemResponse> history = subscriptions.stream()
                .map(this::toHistoryItem)
                .toList();

        return SubscriptionInfoResponse.builder()
                .planName(current.getPlan() != null ? current.getPlan().getName() : null)
                .status(current.getStatus() != null ? current.getStatus().name() : null)
                .nextBillingDate(calculateNextBillingDate(current))
                .price(current.getPlan() != null ? current.getPlan().getPrice() : null)
                .timeUnit(current.getPlan() != null && current.getPlan().getTimeUnit() != null
                        ? current.getPlan().getTimeUnit().name()
                        : null)
                .billingHistory(history)
                .build();
    }

    @Override
    public void unsubscribe() {
        String email = SecurityContextHolder.getContext().getAuthentication().getName();
        Client c = clientRepository.findByEmailAndActive(email,true);
        if(Objects.isNull(c)) throw new BusinessException(ErrorCode.USER_NOT_FOUND);
        Subscription sub = subscriptionRepository.findLatestActiveValidSubscription(c.getId())
                .orElseThrow(() -> new BusinessException(ErrorCode.SUBSCRIPTION_NOT_FOUND));
        sub.setStatus(Status.CANCELED);
        subscriptionRepository.save(sub);
    }

    private SubscriptionHistoryItemResponse toHistoryItem(Subscription subscription) {
        return SubscriptionHistoryItemResponse.builder()
                .planName(subscription.getPlan() != null ? subscription.getPlan().getName() : null)
                .price(subscription.getPlan() != null ? subscription.getPlan().getPrice() : null)
                .timeUnit(subscription.getPlan() != null && subscription.getPlan().getTimeUnit() != null
                        ? subscription.getPlan().getTimeUnit().name()
                        : null)
                .startDate(subscription.getStartAt())
                .status(subscription.getStatus() != null ? subscription.getStatus().name() : null)
                .build();
    }

    private LocalDate calculateNextBillingDate(Subscription subscription) {
        if (subscription.getStartAt() == null || subscription.getPlan() == null || subscription.getPlan().getTimeUnit() == null) {
            return null;
        }

        TimeUnit timeUnit = subscription.getPlan().getTimeUnit();
        if (timeUnit == TimeUnit.MONTHS) {
            return subscription.getStartAt().plusMonths(1);
        }
        if (timeUnit == TimeUnit.YEARS) {
            return subscription.getStartAt().plusYears(1);
        }
        return null;
    }
}
