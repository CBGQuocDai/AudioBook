package org.backend.file.config;

import lombok.Getter;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;

/**
 * Configuration properties class mapping storage access keys and size thresholds.
 */
@Getter
@Configuration
public class FileConfig {

    /**
     * AWS Access Key.
     */
    @Value("${storage.aws.access-key}")
    private String accessKey;

    /**
     * AWS Secret Key.
     */
    @Value("${storage.aws.secret-key}")
    private String secretKey;

    /**
     * AWS Region name.
     */
    @Value("${storage.aws.region}")
    private String region;

    /**
     * S3 cloud bucket destination folder.
     */
    @Value("${storage.aws.bucket-name}")
    private String publicBucket;

    /**
     * Threshold limit governing single uploads size.
     */
    @Value("${storage.max-file-size:104857600}")
    private Long maxFileSize;

}
