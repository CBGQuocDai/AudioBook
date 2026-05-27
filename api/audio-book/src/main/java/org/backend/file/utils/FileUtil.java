package org.backend.file.utils;

import org.backend.file.enums.FileType;
import org.springframework.web.multipart.MultipartFile;

/**
 * Helper utility class for managing operations on files, including validations and format assertion.
 */
public final class FileUtil {

    /**
     * Private constructor to block instantiation.
     */
    private FileUtil() {
    }

    /**
     * Asserts if a file meets expected format constraints based on a category indicator type.
     * Supports matching extensions for images, documents, and audio resources.
     *
     * @param file target multipart file asset
     * @param type target standard format category (image, document, audio, avatar)
     * @return true if file matches expected validation structures, false otherwise
     */
    public static boolean validateFileType(MultipartFile file, String type) {
        if (file == null || file.isEmpty()) {
            return false;
        }

        String originalFilename = file.getOriginalFilename();
        if (originalFilename == null || !originalFilename.contains(".")) {
            return false;
        }

        String extension = getFileExtension(originalFilename).toLowerCase();
        FileType fileType = FileType.fromString(type);

        switch (fileType) {
            case AVATAR:
            case IMAGE:
                return isImageExtension(extension);
            case DOCUMENT:
                return isDocumentExtension(extension);
            case AUDIO:
                return isAudioExtension(extension);
            default:
                return true;
        }
    }

    /**
     * Evaluates if extension matches standard image formats.
     *
     * @param extension target suffix
     * @return match evaluation
     */
    private static boolean isImageExtension(String extension) {
        return extension.matches("^(jpg|jpeg|png|gif|webp)$");
    }

    /**
     * Evaluates if extension matches standard audio formats.
     *
     * @param extension target suffix
     * @return match evaluation
     */
    private static boolean isAudioExtension(String extension) {
        return extension.matches("^(mp3|wav|m4a|aac|flac|ogg|wma)$");
    }

    /**
     * Evaluates if extension matches standard text/document formats.
     *
     * @param extension target suffix
     * @return match evaluation
     */
    private static boolean isDocumentExtension(String extension) {
        return extension.matches("^(pdf|doc|docx|xls|xlsx|ppt|pptx|txt|epub)$");
    }

    /**
     * Resolves extension segment from complete file names.
     *
     * @param filename target full file name
     * @return raw extension string
     */
    private static String getFileExtension(String filename) {
        if (filename == null || !filename.contains(".")) {
            return "";
        }
        return filename.substring(filename.lastIndexOf(".") + 1);
    }
}

