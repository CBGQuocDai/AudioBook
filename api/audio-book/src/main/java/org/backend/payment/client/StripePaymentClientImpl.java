package org.backend.payment.client;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.backend.payment.config.StripeProperties;
import org.backend.payment.exception.PaymentIntegrationException;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.client.RestClientException;
import org.springframework.web.client.RestTemplate;

import java.util.Map;

@Slf4j
@Component
@RequiredArgsConstructor
public class StripePaymentClientImpl implements StripePaymentClient {

    private static final String STRIPE_PAYMENT_INTENT_API = "https://api.stripe.com/v1/payment_intents";

    private final StripeProperties stripeProperties;
    private final RestTemplate restTemplate = new RestTemplate();

    @Override
    public StripePaymentIntentResult createPaymentIntent(Long amount, String currency, String idempotencyKey, String orderId, String userId) {
        try {
            HttpHeaders headers = new HttpHeaders();
            headers.setBearerAuth(stripeProperties.getSecretKey());
            headers.setContentType(MediaType.APPLICATION_FORM_URLENCODED);
            headers.add("Idempotency-Key", idempotencyKey);

            MultiValueMap<String, String> payload = new LinkedMultiValueMap<>();
            payload.add("amount", String.valueOf(amount));
            payload.add("currency", currency.toLowerCase());
            payload.add("automatic_payment_methods[enabled]", "true");
            payload.add("metadata[orderId]", orderId);
            payload.add("metadata[userId]", userId);

            log.info("Creating Stripe PaymentIntent: orderId={}, userId={}, amount={}, currency={}", orderId, userId, amount, currency);

            HttpEntity<MultiValueMap<String, String>> request = new HttpEntity<>(payload, headers);
            Map<String, Object> response = restTemplate.postForObject(STRIPE_PAYMENT_INTENT_API, request, Map.class);

            if (response == null || response.get("id") == null || response.get("client_secret") == null) {
                throw new PaymentIntegrationException("Stripe returned invalid PaymentIntent response");
            }

            return StripePaymentIntentResult.builder()
                    .paymentIntentId(String.valueOf(response.get("id")))
                    .clientSecret(String.valueOf(response.get("client_secret")))
                    .status(String.valueOf(response.get("status")))
                    .build();
        } catch (RestClientException ex) {
            log.error("Stripe PaymentIntent creation failed. orderId={}, userId={}, message={}", orderId, userId, ex.getMessage(), ex);
            throw new PaymentIntegrationException("Failed to create Stripe PaymentIntent", ex);
        }
    }
}


