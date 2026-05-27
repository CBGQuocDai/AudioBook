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
import org.backend.payment.entity.PaymentTransaction;
import org.backend.payment.enums.PaymentStatus;
import org.backend.payment.exception.BadRequestException;
import org.backend.payment.exception.ResourceNotFoundException;
import org.backend.payment.repository.PaymentTransactionRepository;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.List;
import java.util.Objects;

/**
 * Implementation of SubscriptionService.
 * Deals with managing subscription upgrade, cancellation, and retrieval of active subscription information.
 */
@Service
@RequiredArgsConstructor
public class SubscriptionServiceImpl implements SubscriptionService {
    private final ClientRepository clientRepository;
    private final SubscriptionRepository subscriptionRepository;
    private final PlanRepository planRepository;
    private final PaymentTransactionRepository paymentTransactionRepository;

    /**
     * Upgrades a client subscription to Premium.
     * Resolves the plan and payment transaction details to verify amount, maps them to a new subscription.
     *
     * @param req Request containing target premium Plan ID and successful Payment ID.
     * @throws BusinessException if the current client is not found or is forbidden.
     * @throws BadRequestException if plan ID, payment ID are missing, payment was already used,
     *                             or if the payment amount doesn't match the plan price.
     * @throws ResourceNotFoundException if the payment transaction is not found.
     */
    @Override
    public void subscribe(UpPremiumRequest req) {
        String email = SecurityContextHolder.getContext().getAuthentication().getName();
        Client c = clientRepository.findByEmailAndActive(email, true);
        if (Objects.isNull(c)) throw new BusinessException(ErrorCode.USER_NOT_FOUND);
        if (Objects.isNull(req.getPlanId())) {
            throw new BadRequestException("Plan id is required");
        }
        if (Objects.isNull(req.getPaymentId())) {
            throw new BadRequestException("Payment id is required");
        }

        PaymentTransaction paymentTransaction = paymentTransactionRepository.findById(req.getPaymentId())
                .orElseThrow(() -> new ResourceNotFoundException("Payment not found: " + req.getPaymentId()));
        if (!String.valueOf(c.getId()).equals(paymentTransaction.getUserId())) {
            throw new BusinessException(ErrorCode.FORBIDDEN);
        }
        if (paymentTransaction.getStatus() != PaymentStatus.SUCCESS) {
            throw new BadRequestException("Payment is not successful yet");
        }
        if (subscriptionRepository.findByPaymentTransactionId(paymentTransaction.getId()).isPresent()) {
            throw new BadRequestException("Payment has already been used for a subscription");
        }

        Subscription s = new Subscription();
        s.setClient(c);
        Plan p = planRepository.getReferenceById(req.getPlanId());
        if (!Objects.equals(paymentTransaction.getAmount(), p.getPrice())) {
            throw new BadRequestException("Payment amount does not match selected plan");
        }
        s.setPlan(p);
        s.setPaymentTransaction(paymentTransaction);
        s.setStatus(Status.ACTIVE);
        s.setStartAt(LocalDate.now());
        subscriptionRepository.save(s);

    }

    /**
     * Retrieves information about the current client's subscription.
     * Resolves subscription history and calculates current subscription details and next billing date.
     *
     * @return SubscriptionInfoResponse containing current plan, status, next billing date, price, unit, and history list.
     * @throws BusinessException if client is not found.
     */
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

    /**
     * Cancels the currently active premium subscription for the client.
     * Changes status from ACTIVE to CANCELED.
     *
     * @throws BusinessException if client is not found, or active subscription does not exist.
     */
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

    /**
     * Maps a Subscription entity to a SubscriptionHistoryItemResponse DTO.
     *
     * @param subscription The subscription entity.
     * @return Configured SubscriptionHistoryItemResponse.
     */
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

    /**
     * Calculates the next billing date for a subscription based on its start date and time unit duration (Months/Years).
     *
     * @param subscription The subscription details.
     * @return Next billing LocalDate, or null if parameters are insufficient.
     */
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
