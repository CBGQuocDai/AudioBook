package org.backend.file.service;

import org.backend.common.exception.BusinessException;
import org.backend.common.exception.ErrorCode;
import org.backend.common.util.CommonUtil;
import org.backend.file.entity.File;
import org.backend.file.enums.FileType;
import org.backend.file.utils.FileUtil;
import org.backend.user.entity.User;
import org.springframework.web.multipart.MultipartFile;

/**
 * Service interface outlining core capabilities of storage files upload, validation, and metadata persistence.
 */
public interface FileService {

    /**
     * Persists file metadata mapping record details to database.
     *
     * @param file target metadata entity
     * @return the saved {@link File} instance
     */
    File save(File file);

    /**
     * Resolves the threshold property of maximum allowed file size bounds.
     *
     * @return maximum file size allowed in bytes
     */
    Long getMaxFileSize();

    /**
     * Resolves the user identity initiating the current upload workflow.
     *
     * @return the current authenticated {@link User} entity
     */
    User getCurrentUser();

    /**
     * Computes a unique name segment incorporating user details and timestamps to bypass file collision.
     *
     * @param ulid caller identifier string
     * @return formatted destination name sequence
     */
    default String getFileUploadName(String ulid) {
        return ulid
            + "/"
            + CommonUtil.generateRandomAlphanumericString()
            + "-"
            + CommonUtil.getCurrentTimeStamp();
    }

    /**
     * Triggers file validations, resolves storage formats, maps paths, and dispatches uploads to cloud storage bucket (S3), returning the database representation.
     *
     * @param file target raw multipart data
     * @param type designated type parameter
     * @return the persisted {@link File} database metadata instance
     */
    default File uploadFile(MultipartFile file, String type) {
        User user = getCurrentUser();
        validateInputFile(file, type);

        FileType storageFileType = FileType.fromString(type);
        String modifiedFileName = getFileUploadName(user.getId().toString());

        String filePath = createFilePath(modifiedFileName, storageFileType);
        handleUploadFileToCloudProvider(file, modifiedFileName, storageFileType);

        FileType dbFileType = FileType.shouldPersistAsAvatar(storageFileType) ? FileType.AVATAR : storageFileType;

        File audioBookFile = new File();
        audioBookFile.setFileName(file.getOriginalFilename());
        audioBookFile.setFilePath(filePath);
        audioBookFile.setType(dbFileType.getType());
        save(audioBookFile);

        return audioBookFile;
    }

    /**
     * Builds cloud target path using file names and category identifiers.
     *
     * @param originalFilename formatted unique filename
     * @param fileType structured enum type
     * @return absolute path pointer representing the destination reference URL
     */
    String createFilePath(String originalFilename, FileType fileType);

    /**
     * Handles pushing multipart payload streams directly to S3 cloud storage buckets.
     *
     * @param file multipart container
     * @param filePath constructed path pointer
     * @param fileType target file type metadata
     */
    void handleUploadFileToCloudProvider(MultipartFile file, String filePath, FileType fileType);

    /**
     * Validates file size thresholds and verifies file category constraints.
     *
     * @param file target payload file
     * @param type structural format expected
     * @throws BusinessException (FILE_UPLOAD_FAILED) if size threshold is exceeded or if extension is invalid
     */
    default void validateInputFile(MultipartFile file, String type) {
        if (file.getSize() >= getMaxFileSize()) {
            throw new BusinessException(ErrorCode.FILE_UPLOAD_FAILED);
        }
        if (!FileUtil.validateFileType(file, type)) {
            throw new BusinessException(ErrorCode.FILE_UPLOAD_FAILED);
        }
    }
}
