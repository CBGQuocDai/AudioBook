package org.backend.file.dto;

import lombok.Data;
import org.backend.file.entity.File;

import java.io.Serializable;

@Data
public class FileDto implements Serializable {
    private Long id;
    private String filePath;
    private String fileName;

    public FileDto(){}

    public FileDto(File file) {
        if (file == null) {
            return;
        }
        this.id = file.getId();
        this.filePath = file.getUrl() != null && file.getUrl().startsWith("http") ? file.getUrl() : file.getFilePath();
        this.fileName = file.getFileName();
    }

    public FileDto(String filePath) {
        this.filePath = filePath;
    }
}
