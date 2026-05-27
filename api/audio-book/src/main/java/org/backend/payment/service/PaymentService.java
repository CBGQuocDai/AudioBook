package org.backend.payment.service;

import org.backend.payment.dto.request.CreateStripeIntentRequest;
import org.backend.payment.dto.response.CreateStripeIntentResponse;
import org.backend.payment.dto.response.PaymentDetailResponse;

/**
 * Service interface for handling high-level payment actions and operations.
 */
public interface PaymentService {

    /**
     * Initiates and creates a Stripe PaymentIntent.
     *
     * @param request DTO containing the details of the checkout/payment intent request.
     * @return the created PaymentIntent details response.
     * @throws org.backend.payment.exception.BadRequestException if validation constraints or input is incorrect.
     * @throws org.backend.payment.exception.PaymentIntegrationException if error occurs with external Stripe integration.
     */
    CreateStripeIntentResponse createStripeIntent(CreateStripeIntentRequest request);

    /**
     * Retrieves detail details of a payment transaction by internal ID.
     *
     * @param paymentId the unique database payment transaction ID.
     * @return DTO representation of the payment transaction.
     * @throws org.backend.payment.exception.ResourceNotFoundException if the payment record cannot be found.
     */
    PaymentDetailResponse getPayment(Long paymentId);

    /**
     * Updates payment status dynamically based on incoming Stripe webhook events.
     *
     * @param stripePaymentIntentId Stripe PaymentIntent identifier.
     * @param status the updated payment status string from Stripe.
     * @param failureReason explanation of the failure, if applicable.
     * @return DTO containing updated payment transaction details.
     * @throws org.backend.payment.exception.ResourceNotFoundException if transaction with given PaymentIntent ID does not exist.
     */
    PaymentDetailResponse updatePaymentFromStripeEvent(String stripePaymentIntentId, String status, String failureReason);
}

