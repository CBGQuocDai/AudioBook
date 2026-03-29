package org.backend.file.service;

import org.backend.common.exception.BusinessException;
import org.backend.common.exception.ErrorCode;
import org.backend.common.util.CommonUtil;
import org.backend.file.entity.File;
import org.backend.file.enums.FileType;
import org.backend.file.repository.FileRepository;
import org.backend.file.utils.FileUtil;
import org.backend.user.entity.User;
import org.springframework.web.multipart.MultipartFile;

import java.util.ArrayList;
import java.util.List;
import java.util.Set;

public interface FileService {

    File save(File file);

    void saveAll(List<File> files);

    void deleteByFilePath(String filePath);
    
    Long getMaxFileSize();
    
    Long getTotalMaxFileSize();
    
    Set<String> getAllowedDocumentExtensions();
    
    Set<String> getAllowedImageExtensions();

    File getById(Long id);

    List<File> getByIds(List<Long> ids);

    default File getFilePathByFileName(String fileName, FileRepository fileRepository) {
        return fileRepository.findFirstByFileName(fileName).orElse(null);
    }

    String retrieveImagePathByName(String name);

    void handleDeleteFileOnCloudProvider(File file);

    default String getFileUploadName(String ulid) {
        return ulid
            + "/"
            + CommonUtil.generateRandomAlphanumericString()
            + "-"
            + CommonUtil.getCurrentTimeStamp();
    }

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
        audioBookFile.setUrl(filePath);
        audioBookFile.setType(dbFileType.getType());
        save(audioBookFile);

        return audioBookFile;
    }

    default File uploadFile(MultipartFile file, String type, User fileOwner) {
        fileOwner = fileOwner == null ? getCurrentUser() : fileOwner;
        validateInputFile(file, type);

        FileType storageFileType = FileType.fromString(type);
        String modifiedFileName = getFileUploadName(fileOwner.getId().toString());

        String filePath = createFilePath(modifiedFileName, storageFileType);
        handleUploadFileToCloudProvider(file, modifiedFileName, storageFileType);

        FileType dbFileType = FileType.shouldPersistAsAvatar(storageFileType) ? FileType.AVATAR : storageFileType;

        File audioBookFile = new File();
        audioBookFile.setFileName(file.getOriginalFilename());
        audioBookFile.setFilePath(filePath);
        audioBookFile.setUrl(filePath);
        audioBookFile.setType(dbFileType.getType());
        save(audioBookFile);

        return audioBookFile;
    }
    
    User getCurrentUser();
    
    default List<File> uploadMultipleFiles(MultipartFile[] files, String type) {
        User user = getCurrentUser();
        List<File> flexinFiles = new ArrayList<>();

        FileType storageFileType = FileType.fromString(type);
        for (MultipartFile file : files) {
            validateInputFile(file, type);
            String modifiedFileName = getFileUploadName(user.getId().toString());
            String filePath = createFilePath(modifiedFileName, storageFileType);
            handleUploadFileToCloudProvider(file, modifiedFileName, storageFileType);

            FileType dbFileType = FileType.shouldPersistAsAvatar(storageFileType) ? FileType.AVATAR : storageFileType;

            File audioBookFile = new File();
            audioBookFile.setFileName(file.getOriginalFilename());
            audioBookFile.setFilePath(filePath);
            audioBookFile.setUrl(filePath);
            audioBookFile.setType(dbFileType.getType());
            flexinFiles.add(audioBookFile);
        }
        saveAll(flexinFiles);

        return flexinFiles;
    }

    String createFilePath(String originalFilename, FileType fileType);

    void handleUploadFileToCloudProvider(MultipartFile file, String filePath, FileType fileType);

    default void validateInputFile(MultipartFile file, String type) {
        if (file.getSize() >= getMaxFileSize()) {
            throw new BusinessException(ErrorCode.FILE_UPLOAD_FAILED);
        }
        if (!FileUtil.validateFileType(file, type)) {
            throw new BusinessException(ErrorCode.FILE_UPLOAD_FAILED);
        }
    }


    void deleteFiles(Set<File> files);

    default String generatePresignedUrl(String filePath, Integer expiresInSeconds) {
        throw new UnsupportedOperationException("Not implemented");
    }
}

