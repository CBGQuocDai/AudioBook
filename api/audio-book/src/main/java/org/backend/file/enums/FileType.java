package org.backend.file.enums;

/**
 * Enum defining valid supported media formats and file storage targets.
 */
public enum FileType {

    /**
     * User avatar profile image.
     */
    AVATAR("avatar"),

    /**
     * General visual asset or illustration.
     */
    IMAGE("image"),

    /**
     * Reading texts or manuals (e.g. EPUB, PDF).
     */
    DOCUMENT("document"),

    /**
     * Audiobook narrative chapters audio files (e.g. MP3).
     */
    AUDIO("audio");

    /**
     * Raw string identifier for comparison checks.
     */
    private final String type;

    /**
     * Constructs enum associating string mapping values.
     *
     * @param type standard string value
     */
    FileType(String type) {
        this.type = type;
    }

    /**
     * Resolves raw type configuration value.
     *
     * @return raw type string
     */
    public String getType() {
        return type;
    }

    /**
     * Decodes and maps incoming string parameters into respective Enum constants.
     * Defaults to {@code IMAGE} if input matches nothing or is empty.
     *
     * @param type target raw query string
     * @return target matching FileType Enum instance
     */
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

    /**
     * Asserts if specified type belongs to profile pictures.
     *
     * @param type target type parameter
     * @return verification state
     */
    public static boolean shouldPersistAsAvatar(FileType type) {
        return type == AVATAR;
    }
}

