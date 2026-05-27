package org.backend.file.entity;

import jakarta.persistence.*;
import lombok.*;
import lombok.experimental.FieldNameConstants;
import org.backend.common.entity.AbstractAuditingEntity;

/**
 * Entity representation tracking storage and metadata attributes of uploaded files.
 */
@Entity
@Table(name = "file")
@Getter
@Setter
@Builder
@AllArgsConstructor
@NoArgsConstructor
@FieldNameConstants
public class File extends AbstractAuditingEntity<Long> {

    /**
     * Unique file database identifier.
     */
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /**
     * Original human-readable filename when uploaded.
     */
    @Column(name = "file_name")
    private String fileName;

    /**
     * Storage reference path/URI.
     */
    @Column(name = "file_path")
    private String filePath;

    /**
     * Category designation format (e.g. image, audio, document).
     */
    @Column(name = "type")
    private String type;
}
