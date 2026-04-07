package org.backend.book.service;

import org.backend.book.dto.request.UpsertEbookProgressRequest;
import org.backend.book.dto.response.EbookProgressResponse;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

public interface EbookProgressService {

    // Lưu hoặc cập nhật tiến độ đọc (Upsert)
    EbookProgressResponse upsertProgress(UpsertEbookProgressRequest request);

    // Lấy tiến độ hiện tại của 1 cuốn sách cụ thể (để resume khi mở sách)
    EbookProgressResponse getProgressByBookId(Long bookId);

    // Lấy danh sách sách đang đọc dở, sắp xếp theo thời gian gần nhất
    Page<EbookProgressResponse> getMyRecentProgress(Pageable pageable);
}
