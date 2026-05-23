-- Seed admin + 2 demo users.
-- Password for all accounts: 123456
-- Hash algorithm: bcrypt, cost 12.

SET @password_hash = '$2b$12$d5DWVqtofFUD3olpi.OL8.O6L.Z2OJsz9P1Z1WMzkW3k9GK7D37QC';

INSERT INTO users(password, name, email, active, role, created_by, last_modified_by)
VALUES
  (@password_hash, 'Quản trị viên', 'admin@test.com', 1, 'ADMIN', 'seed', 'seed'),
  (@password_hash, 'Minh An', 'minh.user@test.com', 1, 'USER', 'seed', 'seed'),
  (@password_hash, 'Linh Chi', 'linh.user@test.com', 1, 'USER', 'seed', 'seed')
ON DUPLICATE KEY UPDATE
  password = VALUES(password),
  name = VALUES(name),
  active = 1,
  role = VALUES(role),
  last_modified_by = 'seed';

INSERT IGNORE INTO admin(user_id)
SELECT id FROM users WHERE email = 'admin@test.com';

INSERT INTO client(user_id, total_credit)
SELECT id, 260 FROM users WHERE email = 'minh.user@test.com'
ON DUPLICATE KEY UPDATE total_credit = VALUES(total_credit);

INSERT INTO client(user_id, total_credit)
SELECT id, 180 FROM users WHERE email = 'linh.user@test.com'
ON DUPLICATE KEY UPDATE total_credit = VALUES(total_credit);
