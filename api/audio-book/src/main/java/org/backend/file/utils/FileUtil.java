package org.backend.file.utils;

import org.backend.file.enums.FileType;
import org.springframework.web.multipart.MultipartFile;

public final class FileUtil {

    private FileUtil() {
    }

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

    private static boolean isImageExtension(String extension) {
        return extension.matches("^(jpg|jpeg|png|gif|webp)$");
    }

    private static boolean isAudioExtension(String extension) {
        return extension.matches("^(mp3|wav|m4a|aac|flac|ogg|wma)$");
    }

    private static boolean isDocumentExtension(String extension) {
        return extension.matches("^(pdf|doc|docx|xls|xlsx|ppt|pptx|txt|epub)$");
    }

    private static String getFileExtension(String filename) {
        if (filename == null || !filename.contains(".")) {
            return "";
        }
        return filename.substring(filename.lastIndexOf(".") + 1);
    }
}

