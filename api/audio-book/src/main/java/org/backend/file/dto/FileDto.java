package org.backend.file.dto;

import lombok.Data;
import org.backend.file.entity.File;

import java.io.Serializable;

/**
 * DTO mapping class representing metadata details of stored files.
 */
@Data
public class FileDto implements Serializable {

    /**
     * Unique file database identifier.
     */
    private Long id;

    /**
     * Storage reference path/URI.
     */
    private String filePath;

    /**
     * Original uploaded filename.
     */
    private String fileName;

    /**
     * Empty constructor.
     */
    public FileDto(){}

    /**
     * Constructs a FileDto translation mapping fields directly from entity model.
     *
     * @param file source File database entity
     */
    public FileDto(File file) {
        if (file == null) {
            return;
        }
        this.id = file.getId();
        this.filePath = file.getFilePath();
        this.fileName = file.getFileName();
    }
}
