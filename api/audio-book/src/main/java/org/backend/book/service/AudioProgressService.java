package org.backend.book.service;

import org.backend.book.dto.request.UpsertAudioProgressRequest;
import org.backend.book.dto.response.AudioProgressResponse;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

public interface AudioProgressService {

    // Lưu hoặc cập nhật tiến độ nghe (Upsert)
    AudioProgressResponse upsertProgress(UpsertAudioProgressRequest request);

    // Lấy tiến độ hiện tại của 1 cuốn sách cụ thể (để resume khi mở audiobook)
    AudioProgressResponse getProgressByBookId(Long bookId);

    // Lấy danh sách audiobook đang nghe dở, sắp xếp theo thời gian gần nhất
    Page<AudioProgressResponse> getMyRecentProgress(Pageable pageable);
}
