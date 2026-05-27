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

@Service
@RequiredArgsConstructor
public class CreditPlanServiceImpl implements CreditPlanService {

    private static final Pattern DIGIT_PATTERN = Pattern.compile("\\d+");

    private final CreditPlanRepository planRepository;
    private final ClientRepository clientRepository;
    private final CreditTransactionRepository creditTransactionRepository;
    private final PaymentTransactionRepository paymentTransactionRepository;
    private final PaymentService paymentService;

    @Override
    public List<CreditPlan> getPlan() {
        return planRepository.findAll();
    }

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

    private Client getCurrentClient() {
        String email = SecurityContextHolder.getContext().getAuthentication().getName();
        Client client = clientRepository.findByEmailAndActive(email, true);
        if (client == null) {
            throw new BusinessException(ErrorCode.USER_NOT_FOUND);
        }
        return client;
    }

    private void ensurePremium(Client client) {
        Integer activeFlag = clientRepository.isSubscriptionActiveRaw(client.getId());
        boolean isPremium = activeFlag != null && activeFlag == 1;
        if (!isPremium) {
            throw new BusinessException(ErrorCode.FORBIDDEN);
        }
    }

    private String generateCreditOrderId(Long clientId, Long planId) {
        String token = UUID.randomUUID().toString().replace("-", "").substring(0, 8).toUpperCase(Locale.ROOT);
        return "CREDIT_" + clientId + "_" + planId + "_" + token;
    }

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
