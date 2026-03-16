package org.backend.common.entity;

import jakarta.persistence.MappedSuperclass;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.SoftDelete;

@Setter
@Getter
@MappedSuperclass
@SoftDelete(columnName = "is_deleted")
public abstract class SoftDeleteEntity extends AbstractAuditingEntity<Long> {
}
