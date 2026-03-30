package org.backend.book.service;

import org.backend.book.dto.response.CurrentlyReadingResponse;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

public interface CurrentlyReadingService {
    
    Page<CurrentlyReadingResponse> getCurrentlyReading(Pageable pageable);
}
