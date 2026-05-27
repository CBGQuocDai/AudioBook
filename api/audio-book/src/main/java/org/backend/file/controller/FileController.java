package org.backend.file.controller;

import lombok.RequiredArgsConstructor;
import org.backend.common.response.ApiResponse;
import org.backend.file.dto.FileDto;
import org.backend.file.entity.File;
import org.backend.file.service.FileService;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

/**
 * REST controller for handling file operations such as uploading assets.
 */
@RestController
@RequiredArgsConstructor
@RequestMapping("/files")
public class FileController {

    /**
     * File processing service bean.
     */
    private final FileService fileService;

    /**
     * Endpoint to upload a file to the S3 storage bucket.
     * Validates and processes the file, maps it to a database record, and uploads it.
     *
     * @param file the raw multipart file payload from request
     * @param type the structural type of the file (e.g. image, audio, document)
     * @return an {@link ApiResponse} wrapping the processed {@link FileDto} details
     */
    @PostMapping(value = "/upload", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ApiResponse<FileDto> uploadFile(
            @RequestParam("file") MultipartFile file,
            @RequestParam(value = "type", defaultValue = "image") String type
    ) {
        File uploadedFile = fileService.uploadFile(file, type);
        return ApiResponse.<FileDto>builder().data(new FileDto(uploadedFile)).build();
    }
}

