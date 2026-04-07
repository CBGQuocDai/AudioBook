package org.backend.common.util;


import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.ClassPathResource;
import org.springframework.mail.MailException;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.Map;

@Component
@RequiredArgsConstructor
public class EmailUtil {

    private final JavaMailSender mailSender;

    @Value("${spring.mail.username}")
    private String fromEmail;

    public void sendOtpEmail(String toEmail, String otpCode, String title, String message, int expiredMinutes) {
        String subject = title;
        Map<String, String> variables = Map.of(
                "subject", subject,
                "title", title,
                "message", message,
                "otp", otpCode,
                "expiredMinutes", String.valueOf(expiredMinutes)
        );
        String html = buildTemplate("templates/otp.html", variables);
        sendHtml(toEmail, subject, html);
    }

    public void sendHtml(String toEmail, String subject, String htmlContent) {
        try {
            var mimeMessage = mailSender.createMimeMessage();
            var helper = new MimeMessageHelper(mimeMessage, false, StandardCharsets.UTF_8.name());
            helper.setFrom(fromEmail);
            helper.setTo(toEmail);
            helper.setSubject(subject);
            helper.setText(htmlContent, true);
            mailSender.send(mimeMessage);
        } catch (MailException | jakarta.mail.MessagingException exception) {
            throw new RuntimeException("Cannot send email", exception);
        }
    }

    public String buildTemplate(String templatePath, Map<String, String> variables) {
        String template;
        try {
            var resource = new ClassPathResource(templatePath);
            byte[] bytes = resource.getInputStream().readAllBytes();
            template = new String(bytes, StandardCharsets.UTF_8);
        } catch (IOException exception) {
            throw new RuntimeException("Cannot read email template", exception);
        }

        for (var entry : variables.entrySet()) {
            template = template.replace("{{" + entry.getKey() + "}}", entry.getValue());
        }
        return template;
    }
}
