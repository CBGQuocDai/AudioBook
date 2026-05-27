package org.backend.client.service.impl;

import lombok.RequiredArgsConstructor;
import org.backend.client.dto.request.ConfirmCreditPurchaseRequest;
import org.backend.client.dto.request.CreateCreditPurchaseIntentRequest;
import org.backend.client.entity.Client;
import org.backend.client.entity.CreditPlan;
import org.backend.client.entity.CreditTransaction;
import org.backend.client.enums.Status;
import org.backend.client.repository.ClientRepository;
import org.backend.client.repository.CreditPlanRepository;
import org.backend.client.repository.CreditTransactionRepository;
import org.backend.client.service.CreditPlanService;
import org.backend.common.exception.BusinessException;
import org.backend.common.exception.ErrorCode;
import org.backend.payment.dto.request.CreateStripeIntentRequest;
import org.backend.payment.dto.response.CreateStripeIntentResponse;
import org.backend.payment.dto.response.PaymentDetailResponse;
import org.backend.payment.entity.PaymentTransaction;
import org.backend.payment.enums.PaymentStatus;
import org.backend.payment.exception.BadRequestException;
import org.backend.payment.exception.ResourceNotFoundException;
import org.backend.payment.repository.PaymentTransactionRepository;
import org.backend.payment.service.PaymentService;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Locale;
import java.util.Objects;
import java.util.UUID;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Implementation of CreditPlanService.
 * Manages purchasing and confirming credits. Requires an active Premium subscription.
 */
@Service
@RequiredArgsConstructor
public class CreditPlanServiceImpl implements CreditPlanService {

    /**
     * Pattern to extract numeric values from credit plan amount strings.
     */
    private static final Pattern DIGIT_PATTERN = Pattern.compile("\\d+");

    private final CreditPlanRepository planRepository;
    private final ClientRepository clientRepository;
    private final CreditTransactionRepository creditTransactionRepository;
    private final PaymentTransactionRepository paymentTransactionRepository;
    private final PaymentService paymentService;

    /**
     * Fetches all available credit plans.
     *
     * @return List of CreditPlan entities.
     */
    @Override
    public List<CreditPlan> getPlan() {
        return planRepository.findAll();
    }

    /**
     * Creates a Stripe payment intent for credit purchase.
     * Verifies the client's premium status before proceeding.
     *
     * @param request Request containing credit plan ID, payment method, and idempotency key.
     * @return Stripe client secret response.
     * @throws ResourceNotFoundException if the credit plan is not found.
     * @throws BusinessException if the client is not found or is not premium.
     */
    @Override
    @Transactional
    public CreateStripeIntentResponse createPurchaseIntent(CreateCreditPurchaseIntentRequest request) {
        Client client = getCurrentClient();
        ensurePremium(client);

        CreditPlan creditPlan = planRepository.findById(request.getCreditPlanId())
                .orElseThrow(() -> new ResourceNotFoundException("Credit plan not found: " + request.getCreditPlanId()));

        CreateStripeIntentRequest intentRequest = CreateStripeIntentRequest.builder()
                .orderId(generateCreditOrderId(client.getId(), creditPlan.getId()))
                .userId(String.valueOf(client.getId()))
                .amount(creditPlan.getPrice())
                .currency("vnd")
                .paymentMethod(request.getPaymentMethod())
                .idempotencyKey(request.getIdempotencyKey())
                .build();

        return paymentService.createStripeIntent(intentRequest);
    }

    /**
     * Confirms the credit purchase once payment has succeeded.
     * Finds the matching credit plan based on amount, maps it, parses credits, adds credits,
     * and saves both transaction and client entity.
     *
     * @param request Request containing the payment ID.
     * @throws ResourceNotFoundException if the payment record does not exist.
     * @throws BusinessException if forbidden (user ID mismatch).
     * @throws BadRequestException if the payment status is not success, if no plan matches the price,
     *                             or if the credit amount parsed is invalid.
     */
    @Override
    @Transactional
    public void confirmPurchase(ConfirmCreditPurchaseRequest request) {
        Client client = getCurrentClient();
        ensurePremium(client);

        PaymentTransaction paymentTransaction = paymentTransactionRepository.findById(request.getPaymentId())
                .orElseThrow(() -> new ResourceNotFoundException("Payment not found: " + request.getPaymentId()));

        if (!String.valueOf(client.getId()).equals(paymentTransaction.getUserId())) {
            throw new BusinessException(ErrorCode.FORBIDDEN);
        }

        if (paymentTransaction.getStatus() != PaymentStatus.SUCCESS) {
            throw new BadRequestException("Payment is not successful yet");
        }

        CreditTransaction existing = creditTransactionRepository.findByPaymentTransactionId(paymentTransaction.getId())
                .orElse(null);

        if (existing != null) {
            return;
        }

        CreditPlan matchedPlan = planRepository.findAll().stream()
                .filter(plan -> Objects.equals(plan.getPrice(), paymentTransaction.getAmount()))
                .findFirst()
                .orElseThrow(() -> new BadRequestException("Cannot map payment amount to credit plan"));

        int creditsToAdd = parseCredits(matchedPlan.getAmount());
        if (creditsToAdd <= 0) {
            throw new BadRequestException("Credit plan amount is invalid");
        }

        CreditTransaction creditTransaction = new CreditTransaction();
        creditTransaction.setClient(client);
        creditTransaction.setCreditPlan(matchedPlan);
        creditTransaction.setPaymentTransaction(paymentTransaction);
        creditTransaction.setStatus(Status.ACTIVE);
        creditTransactionRepository.save(creditTransaction);

        int currentCredit = client.getTotalCredit() == null ? 0 : client.getTotalCredit();
        client.setTotalCredit(currentCredit + creditsToAdd);
        clientRepository.save(client);
    }

    /**
     * Fetches current client based on authentication context.
     *
     * @return The authenticated Client.
     * @throws BusinessException if user is not found.
     */
    private Client getCurrentClient() {
        String email = SecurityContextHolder.getContext().getAuthentication().getName();
        Client client = clientRepository.findByEmailAndActive(email, true);
        if (client == null) {
            throw new BusinessException(ErrorCode.USER_NOT_FOUND);
        }
        return client;
    }

    /**
     * Verifies that the client has an active subscription.
     * Uses native sql query check `isSubscriptionActiveRaw`.
     *
     * @param client The client to verify.
     * @throws BusinessException with ErrorCode.FORBIDDEN if subscription is not active.
     */
    private void ensurePremium(Client client) {
        Integer activeFlag = clientRepository.isSubscriptionActiveRaw(client.getId());
        boolean isPremium = activeFlag != null && activeFlag == 1;
        if (!isPremium) {
            throw new BusinessException(ErrorCode.FORBIDDEN);
        }
    }

    /**
     * Generates a unique order ID for credit transactions.
     *
     * @param clientId The ID of the client.
     * @param planId The ID of the credit plan.
     * @return Generated order ID string.
     */
    private String generateCreditOrderId(Long clientId, Long planId) {
        String token = UUID.randomUUID().toString().replace("-", "").substring(0, 8).toUpperCase(Locale.ROOT);
        return "CREDIT_" + clientId + "_" + planId + "_" + token;
    }

    /**
     * Parses numeric credit amounts from raw text (e.g. "10 Credits" -> 10).
     *
     * @param rawAmount Raw amount string.
     * @return Parsed credit count, or 0 if parsing fails.
     */
    private int parseCredits(String rawAmount) {
        if (rawAmount == null || rawAmount.isBlank()) {
            return 0;
        }

        Matcher matcher = DIGIT_PATTERN.matcher(rawAmount);
        if (!matcher.find()) {
            return 0;
        }

        try {
            return Integer.parseInt(matcher.group());
        } catch (NumberFormatException ex) {
            return 0;
        }
    }
}
