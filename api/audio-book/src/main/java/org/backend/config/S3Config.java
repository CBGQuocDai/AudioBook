package org.backend.config;


import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import software.amazon.awssdk.auth.credentials.AwsBasicCredentials;
import software.amazon.awssdk.auth.credentials.StaticCredentialsProvider;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.s3.S3Client;

/**
 * Configuration class for Amazon S3 client setup.
 * Uses access key, secret key, and region properties from configuration files.
 */
@Configuration
public class S3Config {

    /**
     * AWS Access Key ID for authentication.
     */
    @Value("${storage.aws.access-key}")
    private String accessKey;

    /**
     * AWS Secret Access Key for authentication.
     */
    @Value("${storage.aws.secret-key}")
    private String secretKey;

    /**
     * Target AWS Region.
     */
    @Value("${storage.aws.region}")
    private String region;

    /**
     * Configures and provides an Amazon S3 client bean.
     * Establishes authentication credentials and the target region for file upload/download operations.
     *
     * @return the configured {@link S3Client} instance
     */
    @Bean
    public S3Client s3Client() {
        AwsBasicCredentials credentials = AwsBasicCredentials.create(accessKey, secretKey);

        return S3Client.builder()
                .region(Region.of(region))
                .credentialsProvider(StaticCredentialsProvider.create(credentials))
                .build();
    }
}
