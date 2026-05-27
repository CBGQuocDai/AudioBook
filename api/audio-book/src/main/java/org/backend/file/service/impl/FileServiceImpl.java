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
import org.springframework.web.multipart.MultipartFile;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;

/**
 * Concrete implementation class implementing S3 storage bucket transfers and files metadata operations.
 */
@Service
@AllArgsConstructor
@Slf4j
public class FileServiceImpl implements FileService {

    /**
     * AWS S3 Client interface.
     */
    private final S3Client s3Client;

    /**
     * Configuration parameters helper.
     */
    private final FileConfig fileConfig;

    /**
     * Persistent storage manager for database metadata.
     */
    private final FileRepository fileRepository;

    /**
     * User administration service interface.
     */
    private final UserService userService;

    /**
     * Persists file metadata record mappings into database.
     *
     * @param file target metadata entity
     * @return the saved {@link File} instance
     */
    @Override
    public File save(File file) {
        return fileRepository.save(file);
    }

    /**
     * Resolves the maximum file size thresholds configured in properties.
     *
     * @return allowed upload limit in bytes
     */
    @Override
    public Long getMaxFileSize() {
        return fileConfig.getMaxFileSize();
    }

    /**
     * Establishes S3 requests, initiates a data stream, and dispatches the payload to targeted S3 folders.
     *
     * @param file target MultipartFile containing binary stream and headers
     * @param filePath unique computed target file name sequence
     * @param fileType the type category used to route file inside target S3 folders
     * @throws BusinessException (FILE_UPLOAD_FAILED) if connection drops or cloud upload fails
     */
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

    /**
     * Retrieves the current logged in session details.
     *
     * @return authentic User details
     */
    @Override
    public User getCurrentUser() {
        return userService.getCurrentLoginUser();
    }

    /**
     * Computes the authentic S3 resource public URL matching constructed naming conventions.
     *
     * @param modifiedFileName target unique path sequence
     * @param fileType structural category type
     * @return complete public resource locator string
     */
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

    /**
     * Resolves target bucket settings.
     *
     * @return bucket name identifier
     */
    private String getBucketName() {
        return fileConfig.getPublicBucket();
    }
}
