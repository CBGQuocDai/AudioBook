package org.backend.file.enums;

public enum FileType {
    AVATAR("avatar"),
    IMAGE("image"),
    DOCUMENT("document"),
    AUDIO("audio");

    private final String type;

    FileType(String type) {
        this.type = type;
    }

    public String getType() {
        return type;
    }

    public static FileType fromString(String type) {
        if (type == null) {
            return IMAGE;
        }
        
        for (FileType fileType : FileType.values()) {
            if (fileType.type.equalsIgnoreCase(type)) {
                return fileType;
            }
        }
        return IMAGE;
    }

    public static boolean isImageFile(FileType type) {
        return type == AVATAR || type == IMAGE;
    }


    public static boolean shouldPersistAsAvatar(FileType type) {
        return type == AVATAR;
    }
}

