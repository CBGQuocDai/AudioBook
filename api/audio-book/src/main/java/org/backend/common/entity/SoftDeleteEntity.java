package org.backend.common.entity;

import jakarta.persistence.MappedSuperclass;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.SoftDelete;

/**
 * Abstract mapped superclass implementing soft deletion for database entities.
 * Automatically adds and manages an 'is_deleted' flag when entities are removed.
 */
@Setter
@Getter
@MappedSuperclass
@SoftDelete(columnName = "is_deleted")
public abstract class SoftDeleteEntity extends AbstractAuditingEntity<Long> {
}
