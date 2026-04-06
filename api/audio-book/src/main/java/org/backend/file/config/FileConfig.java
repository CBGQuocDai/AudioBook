package org.backend.file.config;

import lombok.Getter;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;

@Getter
@Configuration
public class FileConfig {

    @Value("${storage.aws.access-key}")
    private String accessKey;

    @Value("${storage.aws.secret-key}")
    private String secretKey;

    @Value("${storage.aws.region}")
    private String region;

    @Value("${storage.aws.bucket-name}")
    private String publicBucket;

    @Value("${storage.max-file-size:104857600}")
    private Long maxFileSize;

    @Value("${storage.max-total-file-size:1099511627776}")
    private Long totalMaxFileSize;

    @Value("${storage.allowed-image-extensions:jpg,jpeg,png,gif,webp}")
    private String allowedImageExtensions;

    @Value("${storage.allowed-document-extensions:pdf,doc,docx,xls,xlsx,ppt,pptx,txt}")
    private String allowedDocumentExtensions;

}
