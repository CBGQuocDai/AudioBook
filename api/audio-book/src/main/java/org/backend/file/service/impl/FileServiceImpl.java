package org.backend.file.service.impl;

import lombok.AllArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.backend.common.exception.BusinessException;
import org.backend.common.exception.ErrorCode;
import org.backend.file.config.FileConfig;
import org.backend.file.entity.File;
import org.backend.file.enums.FileType;
import org.backend.file.repository.FileRepository;
import org.backend.file.service.FileService;
import org.backend.user.entity.User;
import org.backend.user.service.UserService;
import org.springframework.stereotype.Service;
import org.springframework.util.CollectionUtils;
import org.springframework.web.multipart.MultipartFile;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.*;
import software.amazon.awssdk.services.s3.presigner.S3Presigner;
import software.amazon.awssdk.services.s3.presigner.model.GetObjectPresignRequest;
import software.amazon.awssdk.services.s3.presigner.model.PresignedGetObjectRequest;

import java.time.Duration;
import java.net.URI;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.List;
import java.util.Set;

@Service
@AllArgsConstructor
@Slf4j
public class FileServiceImpl implements FileService {

    private final S3Client s3Client;
    private final S3Presigner s3Presigner;
    private final FileConfig fileConfig;
    private final FileRepository fileRepository;
    private final UserService userService;
    
    @Override
    public File save(File file) {
        return fileRepository.save(file);
    }

    @Override
    public void saveAll(List<File> files) {
        fileRepository.saveAll(files);
    }

    @Override
    public void deleteByFilePath(String filePath) {
        fileRepository.deleteByFilePath(filePath);
    }
    
    @Override
    public Long getMaxFileSize() {
        return fileConfig.getMaxFileSize();
    }
    
    @Override
    public Long getTotalMaxFileSize() {
        return fileConfig.getTotalMaxFileSize();
    }
    
    @Override
    public Set<String> getAllowedDocumentExtensions() {
        String extensionStr = fileConfig.getAllowedDocumentExtensions();
        if (extensionStr != null && !extensionStr.isEmpty()) {
            String[] extensions = extensionStr.split(",");
            return Set.of(extensions);
        }
        return Set.of("pdf", "doc", "docx", "xls", "xlsx");
    }
    
    @Override
    public Set<String> getAllowedImageExtensions() {
        String extensionStr = fileConfig.getAllowedImageExtensions();
        if (extensionStr != null && !extensionStr.isEmpty()) {
            String[] extensions = extensionStr.split(",");
            return Set.of(extensions);
        }
        return Set.of("jpg", "jpeg", "png");
    }

    @Override
    public File getById(Long id) {
        return fileRepository.findById(id)
                .orElseThrow(() -> new BusinessException(ErrorCode.FILE_NOT_FOUND));
    }

    @Override
    public List<File> getByIds(List<Long> ids) {
        return fileRepository.findAllById(ids);
    }
    
    @Override
    public String retrieveImagePathByName(String name) {
        File file = getFilePathByFileName(name, fileRepository);
        if (file == null) {
            throw new BusinessException(ErrorCode.FILE_NOT_FOUND);
        }
        if (!FileType.isImageFile(FileType.fromString(file.getType()))) {
            throw new BusinessException(ErrorCode.FILE_UPLOAD_FAILED);
        }
        return file.getFilePath();
    }

    @Override
    public void handleUploadFileToCloudProvider(MultipartFile file, String filePath, FileType fileType) {
        String targetBucket = getBucketName();
        String s3FilePath = "%s/%s".formatted(fileType.getType(), filePath);

        try {
            PutObjectRequest putRequest = PutObjectRequest.builder()
                    .bucket(targetBucket)
                    .key(s3FilePath)
                    .contentType(file.getContentType())
                    .contentLength(file.getSize())
                    .build();
            
            s3Client.putObject(putRequest, RequestBody.fromInputStream(
                    file.getInputStream(), file.getSize()));
        } catch (Exception e) {
            log.error("Failed to upload file to S3: {}", e.getMessage(), e);
            throw new BusinessException(ErrorCode.FILE_UPLOAD_FAILED);
        }
    }

    @Override
    public void handleDeleteFileOnCloudProvider(File file) {
        String sourceBucket = getBucketName();
        String s3FilePath = "%s/%s".formatted(file.getType(), file.getFilePath());

        try {
            CopyObjectRequest copyRequest = CopyObjectRequest.builder()
                    .sourceBucket(sourceBucket)
                    .sourceKey(s3FilePath)
                    .destinationKey(s3FilePath)
                    .build();
            s3Client.copyObject(copyRequest);

            DeleteObjectRequest deleteRequest = DeleteObjectRequest.builder()
                    .bucket(sourceBucket)
                    .key(s3FilePath)
                    .build();
            s3Client.deleteObject(deleteRequest);
        } catch (S3Exception e) {
            log.error("Failed to delete file from S3: {}", e.getMessage(), e);
        }
    }
    
    @Override
    public User getCurrentUser() {
        return userService.getCurrentLoginUser();
    }
    
    @Override
    public String createFilePath(String modifiedFileName, FileType fileType) {
        String bucketName = getBucketName();
        
        return "https://"
            .concat(bucketName)
            .concat(".s3.")
            .concat(fileConfig.getRegion())
            .concat(".amazonaws.com/")
            .concat(fileType.getType())
            .concat("/")
            .concat(modifiedFileName);
    }
    
    private String getBucketName() {
        return fileConfig.getPublicBucket();
    }
    
    @Override
    public String generatePresignedUrl(String input, Integer expiresInSeconds) {
        try {
            String[] parsed = parseBucketAndKey(input);
            String bucket = parsed[0];
            String key = parsed[1];

            int durationSeconds = expiresInSeconds == null ? 3600 : expiresInSeconds;
            
            GetObjectRequest getObjectRequest = GetObjectRequest.builder()
                    .bucket(bucket)
                    .key(key)
                    .build();

            GetObjectPresignRequest presignRequest = GetObjectPresignRequest.builder()
                    .signatureDuration(Duration.ofSeconds(durationSeconds))
                    .getObjectRequest(getObjectRequest)
                    .build();

            PresignedGetObjectRequest presignedRequest = s3Presigner.presignGetObject(presignRequest);
            return presignedRequest.url().toString();
        } catch (Exception e) {
            log.error("Failed to generate presigned URL: {}", e.getMessage(), e);
            throw new BusinessException(ErrorCode.FILE_UPLOAD_FAILED);
        }
    }

    @Override
    public String readTextContent(File file) {
        if (file == null) {
            throw new BusinessException(ErrorCode.FILE_NOT_FOUND);
        }

        String primarySource = file.getFilePath();
        if (primarySource == null || primarySource.isBlank()) {
            throw new BusinessException(ErrorCode.FILE_NOT_FOUND);
        }

        List<String> sources = new java.util.ArrayList<>();
        sources.add(primarySource);
        if (file.getFileName() != null) {
            sources.add(Path.of("/app/demo-assets", file.getFileName()).toString());
        }

        Exception lastException = null;
        for (String source : sources) {
            try {
                return readTextSource(source);
            } catch (Exception e) {
                lastException = e;
            }
        }

        log.error("Failed to read text content: {}", lastException == null ? "unknown error" : lastException.getMessage(), lastException);
        throw new BusinessException(ErrorCode.FILE_UPLOAD_FAILED);
    }

    private String readTextSource(String source) throws Exception {
        if (source == null || source.isBlank()) {
            throw new java.io.FileNotFoundException("empty text source");
        }
        try {
            if (source.startsWith("file:")) {
                return Files.readString(Paths.get(URI.create(source)), StandardCharsets.UTF_8);
            }
            if (source.startsWith("http://") || source.startsWith("https://")) {
                String[] parsed = parseBucketAndKey(source);
                GetObjectRequest getObjectRequest = GetObjectRequest.builder()
                        .bucket(parsed[0])
                        .key(parsed[1])
                        .build();
                return s3Client.getObjectAsBytes(getObjectRequest).asString(StandardCharsets.UTF_8);
            }
            return Files.readString(Paths.get(source), StandardCharsets.UTF_8);
        } catch (java.nio.file.NoSuchFileException e) {
            throw e;
        }
    }

    private String[] parseBucketAndKey(String input) throws java.net.MalformedURLException {
        String bucket = getBucketName();
        String key;
        if (input.startsWith("http://") || input.startsWith("https://")) {
            java.net.URL url = new java.net.URL(input);
            key = url.getPath().startsWith("/") ? url.getPath().substring(1) : url.getPath();
        } else {
            key = input;
        }
        return new String[]{bucket, key};
    }

    @Override
    public void deleteFiles(Set<File> files) {
        if (CollectionUtils.isEmpty(files)) {
            return;
        }
        for (File file : files) {
            if (file.getFilePath() != null) {
                handleDeleteFileOnCloudProvider(file);
            }
        }
        fileRepository.deleteAll(files);
    }
}
