package org.backend.file.controller;

import lombok.RequiredArgsConstructor;
import org.backend.common.response.ApiResponse;
import org.backend.file.dto.FileDto;
import org.backend.file.entity.File;
import org.backend.file.service.FileService;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequiredArgsConstructor
@RequestMapping("/files")
public class FileController {

    private final FileService fileService;

    @PostMapping(value = "/upload", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ApiResponse<FileDto> uploadFile(
            @RequestParam("file") MultipartFile file,
            @RequestParam(value = "type", defaultValue = "image") String type
    ) {
        File uploadedFile = fileService.uploadFile(file, type);
        return ApiResponse.<FileDto>builder().data(new FileDto(uploadedFile)).build();
    }

    @PostMapping(value = "/upload-multiple", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ApiResponse<List<FileDto>> uploadMultipleFiles(
            @RequestParam("files") MultipartFile[] files,
            @RequestParam(value = "type", defaultValue = "image") String type
    ) {
        List<File> uploadedFiles = fileService.uploadMultipleFiles(files, type);
        List<FileDto> response = uploadedFiles.stream().map(FileDto::new).collect(Collectors.toList());
        return ApiResponse.<List<FileDto>>builder().data(response).build();
    }

    @GetMapping("/{id}")
    public ApiResponse<FileDto> getFileById(@PathVariable Long id) {
        File file = fileService.getById(id);
        return ApiResponse.<FileDto>builder().data(new FileDto(file)).build();
    }

    @GetMapping("/image/{name}")
    public ApiResponse<FileDto> getImagePath(@PathVariable String name) {
        String filePath = fileService.retrieveImagePathByName(name);
        return ApiResponse.<FileDto>builder().data(new FileDto(filePath)).build();
    }

    @GetMapping("/presigned-url")
    public ApiResponse<FileDto> generatePresignedUrl(
            @RequestParam("filePath") String filePath,
            @RequestParam(value = "expiresInSeconds", required = false) Integer expiresInSeconds
    ) {
        String url = fileService.generatePresignedUrl(filePath, expiresInSeconds);
        return ApiResponse.<FileDto>builder().data(new FileDto(url)).build();
    }
}

