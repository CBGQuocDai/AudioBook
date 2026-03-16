package org.backend.common.entity;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.persistence.Column;
import jakarta.persistence.EntityListeners;
import jakarta.persistence.MappedSuperclass;
import lombok.Getter;
import lombok.Setter;
import org.springframework.data.annotation.CreatedBy;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedBy;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;

/**
 * Base abstract class for entities which will hold definitions for created, last modified, created by,
 * last modified by attributes.
 */
@Setter
@Getter
@MappedSuperclass
@EntityListeners(AuditingEntityListener.class)
@JsonIgnoreProperties(value = { "createdBy", "createdAt", "lastModifiedBy", "lastModifiedAt" }, allowGetters = true)
public abstract class AbstractAuditingEntity<T>{

    @CreatedBy
    @Column(name = "created_by", length = 50)
    protected String createdBy;

    @CreatedDate
    @Column(name = "created_at", updatable = false)
    protected LocalDateTime createdAt = LocalDateTime.now();

    @LastModifiedBy
    @Column(name = "last_modified_by", length = 50)
    protected String lastModifiedBy;

    @LastModifiedDate
    @Column(name = "last_modified_at")
    protected LocalDateTime lastModifiedAt = LocalDateTime.now();
}
