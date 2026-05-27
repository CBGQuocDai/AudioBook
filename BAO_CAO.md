# BÁO CÁO DỰ ÁN AUDIOBOOK

## Sinh viên: Đinh Quốc Đại

---

# 1. DANH SÁCH CHỨC NĂNG ĐƯỢC PHÂN CÔNG

## 1.1. Chức năng xác thực và bảo mật

- **Đăng nhập**: Triển khai 2 lựa chọn đăng nhập cho người dùng: đăng nhập bằng tài khoản thường (email + mật khẩu) và đăng nhập bằng tài khoản Google (Google OAuth 2.0). Backend xác thực thông tin, trả về JWT token cho các request tiếp theo.
- **Đăng ký tài khoản**: Người dùng tạo tài khoản mới với email, tên và mật khẩu. Hệ thống gửi mã OTP 6 số qua email để xác thực. Tài khoản chỉ được kích hoạt sau khi nhập đúng OTP.
- **Quên mật khẩu**: Người dùng yêu cầu đặt lại mật khẩu qua email. Hệ thống gửi OTP, người dùng nhập OTP và mật khẩu mới để hoàn tất.

## 1.2. Quản lý thông tin cá nhân của người dùng

- **Xem thông tin cá nhân**: Hiển thị tên, email, ảnh đại diện, trạng thái hội viên (Premium/Base), số credit hiện có.
- **Đổi tên hiển thị**: Cập nhật tên người dùng trên giao diện.
- **Đổi email**: Gồm 2 bước — gửi OTP xác thực đến email mới, nhập OTP để xác nhận đổi email. Trả về JWT token mới với email đã cập nhật.
- **Đổi mật khẩu**: Yêu cầu mật khẩu cũ để xác thực trước khi đặt mật khẩu mới.
- **Đổi ảnh đại diện**: Upload ảnh mới (chụp từ camera hoặc chọn từ thư viện) lên AWS S3, cập nhật avatar.

## 1.3. Quản lý gói hội viên

- **Xem danh sách gói**: Hiển thị các gói hội viên khả dụng (tên gói, giá, chu kỳ: theo tháng hoặc theo năm).
- **Đăng ký gói**: Người dùng chọn gói hội viên, thanh toán qua Stripe PaymentSheet. Backend xác nhận thanh toán thành công → tạo subscription với trạng thái ACTIVE. Người dùng được nâng cấp lên tier PREMIUM.
- **Xem thông tin hội viên**: Hiển thị gói hiện tại, trạng thái (ACTIVE/CANCELED/CHUA_DANG_KY), ngày gia hạn tiếp theo, giá, lịch sử thanh toán.
- **Hủy gói**: Hủy subscription hiện tại, chuyển trạng thái thành CANCELED. Việc hủy có hiệu lực vào cuối chu kỳ hiện tại.

## 1.4. Mua thêm credit

- **Xem danh sách gói credit**: Hiển thị các gói credit khả dụng (số lượng credit, giá).
- **Mua credit**: Chỉ người dùng PREMIUM được phép mua. Chọn gói credit → thanh toán qua Stripe → backend xác nhận → cộng credit vào tài khoản (`totalCredit += creditsToAdd`). Có cơ chế idempotent — mỗi payment chỉ được dùng một lần.

---

# 2. KIẾN TRÚC HỆ THỐNG

## 2.1. Tổng quan

Hệ thống AudioBook được xây dựng theo mô hình **Client-Server**, gồm 2 thành phần chính:

- **Mobile App**: Flutter (Dart) — giao diện người dùng
- **Backend API**: Spring Boot (Java) — xử lý nghiệp vụ, xác thực, thanh toán

Giao tiếp giữa Mobile App và Backend qua **REST API** (HTTP/JSON). Backend tích hợp **Stripe** làm cổng thanh toán và **Ngrok** để expose localhost ra internet cho mobile app kết nối ổn định.

```
┌──────────────────────┐          HTTPS/JSON          ┌──────────────────────────────────────┐
│     MOBILE APP       │ ◄──────────────────────────► │             BACKEND API               │
│    (Flutter/Dart)    │         (qua Ngrok)          │         (Spring Boot / Java)          │
│                      │                              │                                      │
│  ┌────────────────┐  │                              │  ┌────────────────────────────────┐  │
│  │  UI Layer      │  │                              │  │  Controller Layer              │  │
│  │  Screens       │  │                              │  │  AuthController                │  │
│  │  (giao diện)   │  │                              │  │  ClientController              │  │
│  └───────┬────────┘  │                              │  │  SubscriptionController        │  │
│          │           │                              │  │  CreditPlanController          │  │
│          │ sử dụng   │                              │  │  PlanController                │  │
│          ▼           │                              │  └───────────┬────────────────────┘  │
│  ┌────────────────┐  │                              │              │                       │
│  │  Service Layer │  │                              │              ▼                       │
│  │  API Services  │  │                              │  ┌────────────────────────────────┐  │
│  │  (gọi HTTP,    │  │                              │  │  Service Layer                 │  │
│  │   parse JSON   │  │                              │  │  AuthServiceImpl               │  │
│  │   → fill UI)   │  │                              │  │  ClientServiceImpl             │  │
│  └────────────────┘  │                              │  │  SubscriptionServiceImpl       │  │
│                      │                              │  │  CreditPlanServiceImpl         │  │
│  Models (DTOs):      │                              │  └───────────┬────────────────────┘  │
│  auth/models/        │                              │              │                       │
│  payment/models/     │                              │              ▼                       │
│  (dùng bởi Service)  │                              │  ┌────────────────────────────────┐  │
└──────────────────────┘                              │  │  Repository Layer (JPA)        │  │
                                                      │  │  ClientRepository              │  │
                                                      │  │  SubscriptionRepository        │  │
                                                      │  │  CreditPlanRepository          │  │
                                                      │  │  PlanRepository                │  │
                                                      │  │  PaymentTransactionRepository  │  │
                                                      │  └───────────┬────────────────────┘  │
                                                      │              │                       │
                                                      │              ▼                       │
                                                      │  ┌────────────────────────────────┐  │
                                                      │  │  Database Layer                │  │
                                                      │  │  MySQL (JPA/Hibernate)     │  │
                                                      │  └────────────────────────────────┘  │
                                                      │                                      │
                                                      │  Infrastructure (aspect):            │
                                                      │  Redis, AWS S3, Stripe, JavaMail     │
                                                      └──────────────────────────────────────┘
```

## 2.2. Mobile App (Flutter)

Mobile App tổ chức theo 2 tầng chính:

| Tầng | Thư mục | Vai trò |
|------|---------|---------|
| **UI (Screens)** | `lib/src/{auth,profile,payment}/screens/` | Màn hình giao diện, hiển thị dữ liệu, xử lý input người dùng. Gọi Service để lấy dữ liệu, nhận kết quả và `setState` cập nhật UI. |
| **Service** | `lib/src/{auth,payment}/services/` | Gọi HTTP API đến backend. Nhận JSON response → parse thành Model (DTO). Trả dữ liệu đã parse về cho UI. Xử lý error, quản lý token trong header. |

**Models (DTOs)** nằm trong `lib/src/{auth,payment}/models/` — được Service sử dụng để parse JSON từ API, không phải tầng độc lập. Service parse JSON thành model rồi trả về cho UI.

Các thành phần aspect hỗ trợ:

| Thành phần | Thư mục | Vai trò |
|------------|---------|---------|
| Config | `lib/src/core/config/` | Cấu hình base URL, biến môi trường |
| Utils | `lib/src/core/utils/` | Tiện ích: dịch lỗi sang tiếng Việt |
| Routes | `lib/src/util/routes.dart` | Định tuyến màn hình |
| Local Storage | `shared_preferences` | Lưu JWT token, thông tin phiên |

**Luồng dữ liệu**: UI (Screen) → Service (gọi HTTP, parse JSON thành Model) → Backend API → Service (trả Model) → UI (setState hiển thị)

**Thư viện chính**:

| Thư viện | Mục đích |
|----------|----------|
| `http` | Gọi REST API |
| `provider` | State management |
| `flutter_stripe` | Thanh toán Stripe |
| `google_sign_in` | Đăng nhập Google |
| `shared_preferences` | Lưu token cục bộ |
| `image_picker` | Chọn ảnh đại diện |
| `cached_network_image` | Load và cache ảnh từ network |
| `audioplayers` | Phát audio |
| `url_launcher` | Mở URL/file từ backend |

## 2.3. Backend API (Spring Boot)

Backend tổ chức theo kiến trúc phân tầng (Layered Architecture): **Controller → Service → Repository → Database**.

| Tầng | Package | Vai trò |
|------|---------|---------|
| **Controller** | `*.controller` | REST endpoint. Nhận HTTP request, validate input, gọi Service, trả `ApiResponse<T>`. Không chứa logic nghiệp vụ. |
| **Service** | `*.service` / `*.service.impl` | Xử lý toàn bộ logic nghiệp vụ. Điều phối Repository, gọi external services (Stripe, S3, Email). Transactional. |
| **Repository** | `*.repository` | JPA interface. Truy vấn database qua Hibernate. Controller và Service không truy cập database trực tiếp. |
| **Database** | MySQL | Lưu trữ dữ liệu. Kết nối qua JDBC/Hibernate. |

**Entity** (`*.entity`) — ánh xạ bảng database, dùng bởi Repository và Service. **DTO** (`*.dto.request`, `*.dto.response`) — object truyền dữ liệu giữa client-server qua Controller.

Các thành phần aspect (cross-cutting concerns):

| Thành phần | Package | Vai trò |
|------------|---------|---------|
| Security | `config.security` | Spring Security + JWT Filter. Xác thực, phân quyền, CORS. |
| Config | `org.backend.config` | Cấu hình Redis, S3, Swagger, JPA Auditing. |
| Common | `org.backend.common` | Exception handler toàn cục, ApiResponse wrapper, JWT/Email/OTP utilities. |

**Domain chính**:

| Domain | Package | Phụ trách |
|--------|---------|-----------|
| `auth` | `org.backend.auth` | Xác thực: login thường, Google login, OTP, reset/change password, logout |
| `client` | `org.backend.client` | Quản lý người dùng (register, profile), subscription, credit plan |
| `user` | `org.backend.user` | Entity nền tảng (User, Client extends User) |
| `payment` | `org.backend.payment` | Xử lý thanh toán Stripe (intent, webhook, transaction) |
| `file` | `org.backend.file` | Quản lý file upload (AWS S3) |

**Bảo mật**:

- **Spring Security** + **JWT Filter** — xác thực stateless
- **BCrypt** (12 rounds) — mã hóa mật khẩu
- **Endpoint công khai**: `/auth/login`, `/auth/login/google`, `/client/register`, `/auth/otp/**`, `/auth/forgot-password`, `/payments/**`
- **JwtFilter** — kiểm tra token trong header `Authorization: Bearer <token>`
- **Logout** — blacklist token vào Redis với TTL bằng thời gian hết hạn còn lại

**Sơ đồ cơ sở dữ liệu**:

```
┌──────────────┐     ┌──────────────────┐     ┌──────────────┐
│    users     │     │   subscription   │     │    plan      │
│ (base table) │────<│  (client_id FK)  │>────│  (plan_id FK)│
│              │     │  plan_id FK      │     │  name, price │
│  id (PK)     │     │  payment_txn FK  │     │  time_unit   │
│  email       │     │  start_at        │     └──────────────┘
│  password    │     │  status          │
│  name        │     └──────────────────┘
│  role        │
│  active      │     ┌──────────────────┐     ┌──────────────┐
└──────────────┘     │credit_transaction│     │ credit_plan  │
        │            │  client_id FK    │>────│  name, amount│
        │            │  credit_plan FK  │     │  price       │
        ▼            │  payment_id FK   │     └──────────────┘
   ┌──────────┐      └──────────────────┘
   │  client  │
   │(extends  │      ┌──────────────────────┐
   │  user)   │      │ payment_transaction  │
   │total_    │────<│  (1-1 subscription)  │
   │credit    │      │  (1-1 credit_txn)    │
   └──────────┘      │  stripe_intent_id    │
                     │  amount, currency    │
                     │  status              │
                     └──────────────────────┘
```

**Chi tiết kết nối giữa các thành phần**:

| Thành phần | Kết nối đến | Giao thức | Mục đích |
|------------|-------------|-----------|----------|
| Mobile App | Backend API | HTTPS/REST | Gọi API nghiệp vụ qua Ngrok tunnel |
| Backend API | MySQL | JDBC (TCP 5432) | Lưu trữ dữ liệu người dùng, subscription, payment |
| Backend API | Redis | TCP 6379 | Lưu OTP (TTL 5 phút), blacklist JWT khi logout |
| Backend API | AWS S3 | HTTPS | Upload/lấy file ảnh, audio, ebook |
| Backend API | Stripe API | HTTPS | Tạo payment intent, xử lý webhook |
| Backend API | Google OAuth2 | HTTPS | Xác thực Google ID token |
| Backend API | SMTP (Gmail) | TCP 587 | Gửi email OTP xác thực |
| Backend API | Ngrok | TCP tunnel | Expose localhost:8080 ra public internet |

---

---

## 3.2. Sơ đồ cơ sở dữ liệu

Hệ thống sử dụng **MySQL 8.0**. Dưới đây là các bảng liên quan đến chức năng được phân công.

### Bảng `users`

Bảng nền tảng lưu thông tin người dùng. `Client` kế thừa bảng này (JPA inheritance: `@PrimaryKeyJoinColumn(name = "user_id")`), do đó `Client` dùng chung khóa chính với `users`.

| Cột | Kiểu | Mô tả |
|-----|------|-------|
| id | BIGINT (PK, AUTO_INCREMENT) | Khóa chính |
| email | VARCHAR(255) | Email đăng nhập |
| password | VARCHAR(255) | Mật khẩu mã hóa BCrypt |
| name | VARCHAR(255) | Tên hiển thị |
| role | ENUM('USER','ADMIN') | Vai trò |
| active | BOOLEAN | Trạng thái kích hoạt (false → phải xác thực OTP) |
| avatar_file_id | BIGINT (FK → file.id) | Ảnh đại diện |

### Bảng `client`

Bảng mở rộng từ `users`, lưu dữ liệu riêng của người dùng thông thường.

| Cột | Kiểu | Mô tả |
|-----|------|-------|
| user_id | BIGINT (PK, FK → users.id) | Khóa chính, đồng thời là khóa ngoại đến `users` |
| total_credit | INT | Số credit hiện có |

### Bảng `plan`

Lưu danh sách gói hội viên.

| Cột | Kiểu | Mô tả |
|-----|------|-------|
| id | BIGINT (PK) | Khóa chính |
| name | VARCHAR(255) | Tên gói (vd: "Gói Tháng", "Gói Năm") |
| price | BIGINT | Giá (VND) |
| time_unit | ENUM('MONTHS','YEARS') | Chu kỳ: theo tháng hoặc năm |

### Bảng `subscription`

Lưu lịch sử đăng ký gói hội viên.

| Cột | Kiểu | Mô tả |
|-----|------|-------|
| id | BIGINT (PK) | Khóa chính |
| client_id | BIGINT (FK → client.user_id) | Người dùng |
| plan_id | BIGINT (FK → plan.id) | Gói đã chọn |
| payment_transaction_id | BIGINT (FK, UNIQUE) | Giao dịch thanh toán (1-1) |
| start_at | DATE | Ngày bắt đầu |
| status | ENUM('ACTIVE','CANCELED') | Trạng thái |

### Bảng `credit_plan`

Lưu danh sách gói credit.

| Cột | Kiểu | Mô tả |
|-----|------|-------|
| id | BIGINT (PK) | Khóa chính |
| name | VARCHAR(255) | Tên gói (vd: "50 Credits") |
| amount | VARCHAR(255) | Mô tả số lượng (vd: "50 Credits") |
| price | BIGINT | Giá (VND) |

### Bảng `credit_transaction`

Lưu lịch sử mua credit.

| Cột | Kiểu | Mô tả |
|-----|------|-------|
| id | BIGINT (PK) | Khóa chính |
| client_id | BIGINT (FK → client.user_id) | Người dùng |
| credit_plan_id | BIGINT (FK → credit_plan.id) | Gói credit đã mua |
| payment_id | BIGINT (FK, UNIQUE) | Giao dịch thanh toán (1-1) |
| status | ENUM('ACTIVE','CANCELED') | Trạng thái |

### Bảng `payment_transaction`

Lưu mọi giao dịch thanh toán Stripe.

| Cột | Kiểu | Mô tả |
|-----|------|-------|
| id | BIGINT (PK) | Khóa chính |
| payment_code | VARCHAR(64) (UNIQUE) | Mã thanh toán nội bộ |
| order_id | VARCHAR(128) | Mã đơn hàng |
| user_id | VARCHAR(128) | ID người dùng (dạng String) |
| provider | ENUM('STRIPE') | Nhà cung cấp thanh toán |
| method | ENUM('CARD') | Phương thức |
| amount | BIGINT | Số tiền (VND) |
| currency | VARCHAR(10) | Loại tiền tệ |
| status | ENUM('PENDING','SUCCESS','FAILED','CANCELED') | Trạng thái |
| stripe_payment_intent_id | VARCHAR(128) | ID PaymentIntent bên Stripe |
| stripe_client_secret | VARCHAR(255) | Client secret dùng cho Stripe PaymentSheet |
| idempotency_key | VARCHAR(128) (UNIQUE) | Khóa idempotent chống trùng lặp |
| failure_reason | VARCHAR(500) | Lý do thất bại |

### Quan hệ giữa các bảng

```
users ──< client (1-1, kế thừa)
client ──< subscription (1-n)
subscription >── plan (n-1)
subscription >── payment_transaction (1-1)
client ──< credit_transaction (1-n)
credit_transaction >── credit_plan (n-1)
credit_transaction >── payment_transaction (1-1)
```

---

## 3.3. Chức năng đăng nhập bằng tài khoản thường

### Mobile App

**Màn hình**: `lib/src/auth/screens/login_screen.dart`

**`_submitLogin`**: validate input rồi gọi service đăng nhập
	- Input: không (đọc từ `_emailController`, `_passwordController`)
	- Output: void (điều hướng sang home hoặc hiển thị lỗi)

**Service**: `AuthApiService` (`lib/src/auth/services/auth_api_service.dart`)

**`login`**: gửi request đăng nhập lên backend
	- Input: request: LoginRequest {email: String, password: String}
	- Output: ApiResponse<TokenResponse> {token: String, userInfo: UserInfo}
	- Gọi API ngoài: `POST /auth/login`, body: `{email, password}`

Luồng sau khi có token: gọi `TokenStorageService.saveAuthSession(token, userId, email, role)` → `Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, ...)`.

### Backend

**Tầng Controller** — `AuthController` (`auth/controller/AuthController.java`)

**`login`**: tiếp nhận request và ủy thác cho service
	- Input: loginRequest: LoginRequest {email: String, password: String}
	- Output: ApiResponse<TokenResponse>

**Tầng Service** — `AuthServiceImpl` (`auth/service/impl/AuthServiceImpl.java`)

**`login`**: xác thực email/password và tạo JWT
	- Input: loginRequest: LoginRequest {email: String, password: String}
	- Output: TokenResponse {token: String, userInfo: UserInfo}
	- Xử lý:
		1. `userRepository.findByEmailAndActive(email, true)` — tìm user active
		2. `passwordEncoder.matches(password, user.getPassword())` — so sánh BCrypt
		3. `jwtUtil.generateToken(user)` — tạo JWT (claims: subject=email, id, role)

**Tầng Repository** — `UserRepository` (`user/repository/UserRepository.java`)

**`findByEmailAndActive`**: truy vấn user theo email và trạng thái active
	- Input: email: String, active: boolean
	- Output: User (null nếu không tìm thấy)
	- Query: JPA derived query — `WHERE email = ?1 AND active = ?2`

---

## 3.4. Chức năng đăng nhập bằng Google

### Mobile App

**Màn hình**: `lib/src/auth/screens/login_screen.dart`

**`_loginWithGoogle`**: đăng nhập qua Google OAuth
	- Input: không
	- Output: void (điều hướng home hoặc hiển thị lỗi)
	- Xử lý:
		1. `GoogleAuthService.signIn()` → `GoogleSignInAccount`
		2. `GoogleAuthService.getIdToken()` → ID token
		3. `_authApiService.loginWithGoogle(idToken)`

**Service**: `GoogleAuthService` (`lib/src/auth/services/google_auth_service.dart`)

**`signIn`**: mở Google Sign-In dialog hệ thống
	- Input: không
	- Output: GoogleSignInAccount (null nếu hủy)
	- Cấu hình: `serverClientId` từ biến môi trường `GOOGLE_WEB_CLIENT_ID`

**`getIdToken`**: lấy ID token từ Google account
	- Input: không
	- Output: String (ID token, null nếu chưa đăng nhập Google)

**Service**: `AuthApiService`

**`loginWithGoogle`**: gửi Google ID token lên backend
	- Input: idToken: String
	- Output: ApiResponse<TokenResponse> {token: String, userInfo: UserInfo}
	- Gọi API ngoài: `POST /auth/login/google`, body: `{idToken}`

### Backend

**Tầng Controller** — `AuthController`

**`loginWithGoogle`**: tiếp nhận Google ID token
	- Input: request: GoogleLoginRequest {idToken: String}
	- Output: ApiResponse<TokenResponse>

**Tầng Service** — `AuthServiceImpl`

**`loginWithGoogle`**: xác thực Google ID token và tạo/login user
	- Input: request: GoogleLoginRequest {idToken: String}
	- Output: TokenResponse {token: String, userInfo: UserInfo}
	- Xử lý:
		1. `GoogleIdTokenVerifier` xác thực ID token với Google API (audience = `googleOauthClientId`)
		2. Lấy email, name từ payload. Kiểm tra `emailVerified`
		3. `clientRepository.findByEmail(email)` — tìm Client
		4. Nếu chưa có: tạo mới `Client` (password=UUID+BCrypt, role=USER, active=true)
		5. Nếu có: kích hoạt lại nếu inactive. Lưu + tạo JWT

**Tầng Repository** — `ClientRepository` (`client/repository/ClientRepository.java`)

**`findByEmail`**: tìm Client theo email
	- Input: email: String
	- Output: Client (null nếu không tồn tại)
	- Query: JPA derived query — `WHERE email = ?1`

### API ngoài

| Mô tả | Phương thức | Endpoint | Request | Response |
|-------|-------------|----------|---------|----------|
| Xác thực Google ID token | POST | `https://oauth2.googleapis.com/token` | idToken | Payload {email, name, emailVerified} |

Gọi qua `GoogleIdTokenVerifier.verify(idToken)` — thư viện `com.google.api-client`.

---

## 3.5. Chức năng đăng ký tài khoản

### Mobile App

**Màn hình**: `lib/src/auth/screens/register_screen.dart`

**`_submitRegister`**: validate form đăng ký và gửi lên backend
	- Input: không (đọc từ `_nameController`, `_emailController`, `_passwordController`, `_confirmPasswordController`)
	- Output: void (điều hướng sang VerifyOtpScreen)

**Service**: `AuthApiService`

**`register`**: gửi yêu cầu đăng ký
	- Input: request: RegisterRequest {name: String, email: String, password: String}
	- Output: ApiResponse<void>
	- Gọi API ngoài: `POST /client/register`, body: `{name, email, password}`

**Màn hình**: `lib/src/auth/screens/verify_otp_screen.dart`

**`_submitOtp`**: xác thực OTP và kích hoạt tài khoản
	- Input: không (đọc OTP từ input field, nhận email + purpose từ arguments)
	- Output: void (lưu phiên → điều hướng home)
	- Xử lý:
		1. `verifyOtp(VerifyOtpRequest)` → token (authority=VERIFY_EMAIL)
		2. `activeAccount(token)` → token chính thức

**Service**: `AuthApiService`

**`verifyOtp`**: xác thực mã OTP
	- Input: request: VerifyOtpRequest {email: String, otp: String, otpPurpose: String}
	- Output: ApiResponse<TokenResponse>

**`activeAccount`**: kích hoạt tài khoản
	- Input: token: String (OTP token, gửi trong header Authorization)
	- Output: ApiResponse<TokenResponse>

### Backend

**Tầng Controller** — `ClientController`

**`register`**: tiếp nhận đăng ký
	- Input: req: RegisterRequest {name: String, email: String, password: String}
	- Output: ApiResponse<void>

**Tầng Service** — `ClientServiceImpl`

**`register`**: tạo tài khoản mới (inactive) và gửi OTP
	- Input: registerRequest: RegisterRequest {name: String, email: String, password: String}
	- Output: void
	- Xử lý:
		1. Mã hóa password BCrypt, gán avatar mặc định (file id=4)
		2. Nếu email đã tồn tại và inactive → cập nhật; ngược lại → lưu `Client` mới
		3. `OtpCodeUtil.generateOtpCode()` → OTP 6 số
		4. `cache.opsForValue().set(email, otp, 5, MINUTES)` — lưu Redis
		5. `EmailUtil.sendOtpEmail(email, otp, ...)` — gửi email

**Tầng Repository** — `ClientRepository`

**`findByEmail`**: kiểm tra email đã tồn tại chưa
	- Input: email: String
	- Output: Client

**Tầng Controller** — `AuthController`

**`verifyOtp`**: xác thực OTP
	- Input: req: VerifyOtpRequest {email: String, otp: String, otpPurpose: String}
	- Output: ApiResponse<TokenResponse>

**Tầng Service** — `AuthServiceImpl`

**`verifyOtp`**: so khớp OTP và cấp token tạm
	- Input: otp: VerifyOtpRequest {email: String, otp: String, otpPurpose: String}
	- Output: TokenResponse {token: String, userInfo: UserInfo}
	- Xử lý: `userRepository.findByEmail(email)` → `cache.opsForValue().get(email)` so OTP → xóa OTP khỏi Redis → tạo JWT (purpose=otpPurpose)

**Tầng Repository** — `UserRepository`

**`findByEmail`**: tìm user theo email
	- Input: email: String
	- Output: User

**Tầng Controller** — `AuthController`

**`activeAccount`**: kích hoạt tài khoản (yêu cầu authority `VERIFY_EMAIL`)
	- Input: token: String (từ header Authorization)
	- Output: ApiResponse<TokenResponse>

**Tầng Service** — `AuthServiceImpl`

**`activeAccount`**: set active=true và cấp token chính thức
	- Input: token: String (JWT của bước OTP)
	- Output: TokenResponse {token: String, userInfo: UserInfo}
	- Xử lý: lấy email từ SecurityContext → `userRepository.findByEmailAndActive(email, false)` → set active=true → blacklist token OTP vào Redis → tạo JWT mới

### API ngoài

| Mô tả | Phương thức | Endpoint | Request | Response |
|-------|-------------|----------|---------|----------|
| Gửi email OTP | SMTP | `smtp.gmail.com:587` | Email (to, subject, HTML body) | Không |

Gọi qua `JavaMailSender` — Spring Boot Mail.

---

## 3.6. Chức năng quên mật khẩu

### Mobile App

**Màn hình**: `lib/src/auth/screens/forgot_password_screen.dart`

**`_submitForgotPassword`**: gửi yêu cầu quên mật khẩu
	- Input: không (đọc email từ input field)
	- Output: void (điều hướng sang RecoverPasswordScreen)
	- Gọi: `_authApiService.forgotPassword(OtpRequest(email: email))`

**Màn hình**: `lib/src/auth/screens/recover_password_screen.dart`

**`_submitReset`**: xác thực OTP và đặt lại mật khẩu
	- Input: không (đọc OTP + mật khẩu mới từ form)
	- Output: void (điều hướng về login)
	- Xử lý:
		1. `verifyOtp(VerifyOtpRequest(email, otp, resetPassword))` → token (authority=RESET_PASSWORD)
		2. `resetPassword(token, ResetPasswordRequest(newPassword))`

**Service**: `AuthApiService`

**`forgotPassword`**: gửi yêu cầu quên mật khẩu lên backend
	- Input: request: OtpRequest {email: String}
	- Output: ApiResponse<void>
	- Gọi API ngoài: `POST /auth/forgot-password`, body: `{email}`

**`resetPassword`**: đặt mật khẩu mới
	- Input: token: String, request: ResetPasswordRequest {password: String}
	- Output: ApiResponse<void>
	- Gọi API ngoài: `POST /auth/reset-password`, header: `Authorization: Bearer <token>`, body: `{password}`

### Backend

**Tầng Controller** — `AuthController`

**`forgotPassword`**: yêu cầu OTP đặt lại mật khẩu
	- Input: req: OtpRequest {email: String}
	- Output: ApiResponse<void>

**Tầng Service** — `AuthServiceImpl`

**`forgotPassword`**: sinh OTP và gửi email
	- Input: req: OtpRequest {email: String}
	- Output: void
	- Xử lý: `userRepository.existsByEmailAndActive(email, true)` → sinh OTP 6 số → `cache.opsForValue().set(email, otp, 5, MINUTES)` → `EmailUtil.sendOtpEmail(...)`

**Tầng Repository** — `UserRepository`

**`existsByEmailAndActive`**: kiểm tra user tồn tại và active
	- Input: email: String, active: boolean
	- Output: boolean

**Tầng Controller** — `AuthController`

**`resetPassword`**: đặt mật khẩu mới (yêu cầu authority `RESET_PASSWORD`)
	- Input: token (header), req: ResetPasswordRequest {password: String}
	- Output: ApiResponse<void>

**Tầng Service** — `AuthServiceImpl`

**`resetPassword`**: cập nhật mật khẩu
	- Input: req: ResetPasswordRequest {password: String}, token: String
	- Output: void
	- Xử lý: lấy email từ SecurityContext → `userRepository.findByEmailAndActive(email, true)` → `passwordEncoder.encode(password)` → blacklist token OTP vào Redis

### API ngoài

| Mô tả | Phương thức | Endpoint | Request | Response |
|-------|-------------|----------|---------|----------|
| Gửi email OTP | SMTP | `smtp.gmail.com:587` | Email | Không |

---

## 3.7. Chức năng quản lý thông tin cá nhân

### Mobile App

**Màn hình chính**: `lib/src/profile/screens/profile_screen.dart`

**`_loadProfile`**: tải thông tin người dùng
	- Input: không (lấy token từ `TokenStorageService`)
	- Output: void
	- Gọi: `_authApiService.getCurrentUser(token)`

**Service**: `AuthApiService`

**`getCurrentUser`**: lấy thông tin người dùng hiện tại
	- Input: token: String
	- Output: ApiResponse<UserInfo> {id: int, name: String, email: String, role: String, tier: String, avatarUrl: String, totalCredit: int}
	- Gọi API ngoài: `GET /client/me`

**Màn hình**: `lib/src/profile/screens/change_username_screen.dart`

**`changeUserName`**: cập nhật tên
	- Input: token: String, name: String
	- Output: ApiResponse<UserInfo>
	- Gọi API ngoài: `PUT /client/change-name`, body: `{name}`

**Màn hình**: `lib/src/profile/screens/change_email_screen.dart`

Bước 1: **`preChangeEmail`**
	- Input: token: String, newEmail: String
	- Output: ApiResponse<void>
	- Gọi API ngoài: `POST /client/email/pre-change`, body: `{newEmail}`

Bước 2: **`changeEmail`**
	- Input: token: String, otp: String, newEmail: String
	- Output: ApiResponse<TokenResponse>
	- Gọi API ngoài: `PUT /client/email/change`, body: `{otp, newEmail}`

**Màn hình**: `lib/src/profile/screens/change_password_screen.dart`

**`changePassword`**: đổi mật khẩu
	- Input: token: String, request: ChangePasswordRequest {oldPassword: String, newPassword: String}
	- Output: ApiResponse<void>
	- Gọi API ngoài: `POST /auth/change-password`, header `Authorization`, body `{oldPassword, newPassword}`

**Đổi avatar**: `_pickAndSaveAvatar()` (trong `profile_screen.dart`)

**`uploadAvatarFile`**: upload ảnh lên S3
	- Input: token: String, file: File
	- Output: ApiResponse<AvatarFile> {id: int, filePath: String}
	- Gọi API ngoài: `POST /files/upload?type=image`, multipart form-data

**`changeAvatar`**: cập nhật avatar
	- Input: token: String, fileId: int
	- Output: ApiResponse<AvatarFile>
	- Gọi API ngoài: `PUT /client/avatar/change`, body: `{id}`

**Đăng xuất**: `_logout()` (trong `profile_screen.dart`)

**`logout`**: blacklist token trên backend
	- Input: token: String
	- Output: ApiResponse<void>
	- Gọi API ngoài: `DELETE /auth/logout`, header `Authorization: Bearer <token>`

### Backend

**Tầng Controller** — `ClientController`

**`me`**: trả thông tin người dùng
	- Input: không (email từ SecurityContext)
	- Output: ApiResponse<ClientResponse>

**Tầng Service** — `ClientServiceImpl`

**`me`**: trả thông tin kèm tier
	- Input: không
	- Output: ClientResponse {id: Long, name: String, email: String, role: String, tier: String, avatarUrl: String, totalCredit: Integer}
	- Xử lý: `clientRepository.findByEmailAndActive(email, true)` → `clientRepository.isSubscriptionActiveRaw(clientId)` — nếu = 1: tier=PREMIUM, ngược lại: tier=BASE

**Tầng Repository** — `ClientRepository`

**`findByEmailAndActive`**: tìm Client theo email và active
	- Input: email: String, active: boolean
	- Output: Client

**`isSubscriptionActiveRaw`**: native query kiểm tra subscription còn hiệu lực
	- Input: clientId: Long
	- Output: Integer (1 = active, 0 hoặc NULL = không)
	- Query: `SELECT EXISTS (SELECT 1 FROM subscription s JOIN plan p ... WHERE s.client_id = :clientId AND s.status != 'PENDING' AND (DATE_ADD(s.start_at, INTERVAL ...)) > NOW())`

---

**Tầng Controller** — `ClientController`

**`changeName`**: cập nhật tên
	- Input: req: ChangeNameRequest {name: String}
	- Output: ApiResponse<ClientResponse>

**Tầng Service** — `ClientServiceImpl`

**`changeName`**: cập nhật tên và lưu
	- Input: name: String
	- Output: ClientResponse

---

**Tầng Controller** — `ClientController`

**`preChangEmailRequest`**: gửi OTP đến email mới
	- Input: req: PreChangeEmailRequest {newEmail: String}
	- Output: ApiResponse<void>

**Tầng Service** — `ClientServiceImpl`

**`preChangEmailRequest`**: kiểm tra email chưa tồn tại → sinh OTP → gửi email
	- Input: email: String
	- Output: void
	- Xử lý: `clientRepository.existsByEmailAndActive(email, true)` → `OtpCodeUtil.generateOtpCode()` → `cache.opsForValue().set(email, otp, 5, MINUTES)` → `EmailUtil.sendOtpEmail(...)`

**Tầng Repository** — `ClientRepository`

**`existsByEmailAndActive`**: kiểm tra email đã được dùng chưa
	- Input: email: String, active: boolean
	- Output: boolean

---

**Tầng Controller** — `ClientController`

**`changeEmail`**: xác nhận đổi email
	- Input: req: ChangeEmailRequest {newEmail: String, otp: String}, token: String
	- Output: ApiResponse<TokenResponse>

**Tầng Service** — `ClientServiceImpl`

**`changeEmail`**: cập nhật email + blacklist token cũ + tạo JWT mới
	- Input: req: ChangeEmailRequest, token: String
	- Output: TokenResponse
	- Xử lý: lấy email cũ từ `jwtUtil.getClaims(token).getSubject()` → `cache.opsForValue().get(newEmail)` so OTP → `client.email = newEmail` → xóa OTP Redis → blacklist token cũ → `jwtUtil.generateToken(client)`

---

**Tầng Controller** — `ClientController`

**`changeAvatar`**: cập nhật ảnh đại diện
	- Input: fileDto: FileDto {id: Long}
	- Output: ApiResponse<FileDto>

**Tầng Service** — `ClientServiceImpl`

**`changeAvatar`**: gán file avatar mới
	- Input: fileDto: FileDto {id: Long}
	- Output: FileDto
	- Xử lý: `fileRepository.findById(id)` → `client.avatarFile = file` → `clientRepository.save(client)`

**Tầng Repository** — `FileRepository` (`file/repository/FileRepository.java`)

**`findById`**: tìm file theo id (kế thừa từ `JpaRepository`)
	- Input: id: Long
	- Output: Optional<File>

---

**Tầng Controller** — `AuthController`

**`changePassword`**: đổi mật khẩu
	- Input: req: ChangePasswordRequest {oldPassword: String, newPassword: String}
	- Output: ApiResponse<void>

**Tầng Service** — `AuthServiceImpl`

**`changePassword`**: kiểm tra mật khẩu cũ và cập nhật mới
	- Input: req: ChangePasswordRequest {oldPassword: String, newPassword: String}
	- Output: void
	- Xử lý: lấy email từ SecurityContext → `userRepository.findByEmailAndActive(email, true)` → `passwordEncoder.matches(oldPassword, user.getPassword())` → nếu sai: `OLD_PASSWORD_INCORRECT` → nếu đúng: `passwordEncoder.encode(newPassword)` + lưu

---

**Tầng Controller** — `AuthController`

**`logout`**: vô hiệu hóa token
	- Input: token: String (từ header Authorization)
	- Output: ApiResponse<void>

**Tầng Service** — `AuthServiceImpl`

**`logout`**: blacklist token vào Redis
	- Input: token: String
	- Output: void
	- Xử lý: `jwtUtil.getClaims(token)` → `cache.opsForValue().set(claims.getId(), token, remainingTTL, MILLISECONDS)`

### API ngoài

| Mô tả | Phương thức | Endpoint | Request | Response |
|-------|-------------|----------|---------|----------|
| Upload file lên S3 | PUT | `s3://<bucket>/<key>` | Multipart file | File metadata |

Gọi qua `AmazonS3.putObject(...)` — AWS SDK.

---

## 3.8. Chức năng đăng ký gói hội viên

### Mobile App

**Màn hình**: `lib/src/profile/screens/premium_plan_screen.dart`

**`_loadData`**: tải danh sách gói và thông tin user
	- Input: không (lấy token từ `TokenStorageService`)
	- Output: void
	- Gọi: `_planApiService.getPlans(token)` + `_authApiService.getCurrentUser(token)`

**`_payPremium`**: thực hiện thanh toán và đăng ký gói
	- Input: không (đọc `_selectedPlanModel`, `_currentUserId`)
	- Output: void (điều hướng về profile với result=true)
	- Xử lý:
		1. `createStripeIntent(...)` → `clientSecret`
		2. `Stripe.instance.initPaymentSheet(...)` + `presentPaymentSheet()`
		3. `waitForPaymentStatus(token, paymentId)` — poll đến terminal
		4. Nếu SUCCESS: `subscribe(token, planId, paymentId)`

**Service**: `PlanApiService` (`lib/src/payment/services/plan_api_service.dart`)

**`getPlans`**: lấy danh sách gói hội viên
	- Input: token: String
	- Output: List<PlanModel> [{id: int, name: String, price: int, timeUnit: String}]
	- Gọi API ngoài: `GET /plans`

**Service**: `PaymentApiService` (`lib/src/payment/services/payment_api_service.dart`)

**`createStripeIntent`**: tạo Stripe PaymentIntent qua backend
	- Input: token: String, orderId: String, userId: String, amount: int, currency: String, paymentMethod: String, idempotencyKey: String
	- Output: CreateStripeIntentResponse {paymentId: int, stripePaymentIntentId: String, clientSecret: String}
	- Gọi API ngoài: `POST /payments/stripe/create-intent`, body: `{orderId, userId, amount, currency, paymentMethod, idempotencyKey}`

**`waitForPaymentStatus`**: poll trạng thái thanh toán
	- Input: token: String, paymentId: int
	- Output: PaymentDetailResponse {paymentId: int, status: String, ...}
	- Gọi API ngoài: `GET /payments/{paymentId}` (poll mỗi 2s, tối đa 6 lần)

**`subscribe`**: đăng ký subscription sau thanh toán thành công
	- Input: token: String, planId: int, paymentId: int
	- Output: void
	- Gọi API ngoài: `POST /subscription`, body: `{planId, paymentId}`

### Backend

**Tầng Controller** — `PaymentController` (`payment/controller/PaymentController.java`)

**`createStripeIntent`**: tạo giao dịch Stripe
	- Input: request: CreateStripeIntentRequest {orderId: String, userId: String, amount: Long, currency: String, paymentMethod: String, idempotencyKey: String}
	- Output: ApiResponse<CreateStripeIntentResponse>

**Tầng Service** — `PaymentServiceImpl` (`payment/service/impl/PaymentServiceImpl.java`)

**`createStripeIntent`**: tạo PaymentIntent trên Stripe và lưu PaymentTransaction
	- Input: request: CreateStripeIntentRequest
	- Output: CreateStripeIntentResponse {paymentId: Long, stripePaymentIntentId: String, clientSecret: String}
	- Xử lý:
		1. Kiểm tra idempotency: `paymentTransactionRepository.findByIdempotencyKey(key)` → nếu có → trả luôn
		2. `stripePaymentClient.createPaymentIntent(amount, currency, idempotencyKey, orderId, userId)` — gọi Stripe API
		3. Tạo `PaymentTransaction` (status=PENDING, paymentCode="PAY_...") → `paymentTransactionRepository.saveAndFlush()`

**Tầng Repository** — `PaymentTransactionRepository` (`payment/repository/PaymentTransactionRepository.java`)

**`findByIdempotencyKey`**: kiểm tra trùng lặp
	- Input: idempotencyKey: String
	- Output: Optional<PaymentTransaction>

Webhook `POST /payments/stripe/webhook` → `PaymentServiceImpl.updatePaymentFromStripeEvent()` cập nhật `PaymentTransaction.status = SUCCESS` khi Stripe gửi event `payment_intent.succeeded`.

---

**Tầng Controller** — `PlanController` (`client/controller/PlanController.java`)

**`getPlans`**: trả danh sách gói hội viên
	- Input: không
	- Output: ApiResponse<List<PlanResponse>>

**Tầng Service** — `PlanServiceImpl` (`client/service/impl/PlanServiceImpl.java`)

**`getAllPlans`**: truy vấn toàn bộ Plan
	- Input: không
	- Output: List<PlanResponse> [{id: Long, name: String, price: Long, timeUnit: String}]

**Tầng Repository** — `PlanRepository`

**`findAll`**: lấy toàn bộ gói (kế thừa `JpaRepository`)
	- Input: không
	- Output: List<Plan>

---

**Tầng Controller** — `SubscriptionController`

**`subscribe`**: đăng ký subscription
	- Input: req: UpPremiumRequest {planId: Long, paymentId: Long}
	- Output: ApiResponse<void>

**Tầng Service** — `SubscriptionServiceImpl`

**`subscribe`**: tạo subscription sau khi thanh toán
	- Input: req: UpPremiumRequest {planId: Long, paymentId: Long}
	- Output: void
	- Xử lý:
		1. `clientRepository.findByEmailAndActive(email, true)` — lấy Client
		2. `paymentTransactionRepository.findById(paymentId)` — tìm payment
		3. Validate: payment.userId == client.id, payment.status == SUCCESS, payment chưa có subscription, payment.amount == plan.price
		4. Tạo `Subscription` (client, plan, paymentTransaction, startAt=now, status=ACTIVE) → `subscriptionRepository.save()`

**Tầng Repository** — `SubscriptionRepository`

**`findByPaymentTransactionId`**: kiểm tra payment đã có subscription chưa
	- Input: paymentTransactionId: Long
	- Output: Optional<Subscription>

### API ngoài

| Mô tả | Phương thức | Endpoint | Request | Response |
|-------|-------------|----------|---------|----------|
| Tạo Stripe PaymentIntent | POST | `https://api.stripe.com/v1/payment_intents` | amount, currency, payment_method_types, idempotency_key, metadata | PaymentIntent {id, client_secret} |
| Stripe Webhook | POST | (do Stripe gọi về backend) | Event {type, data.object} | Không |

Gọi qua `StripePaymentClient` (wrapper quanh Stripe Java SDK). Webhook được Stripe CLI forward về `localhost:8080/api/payments/stripe/webhook`.

---

## 3.9. Chức năng hủy gói hội viên

### Mobile App

**Màn hình**: `lib/src/profile/screens/subscription_screen.dart`

**`_loadData`**: tải thông tin hội viên
	- Input: không (lấy token từ `TokenStorageService`)
	- Output: void
	- Gọi: `_paymentApiService.getSubscriptionInfo(token)`

**`_cancelMembership`**: hủy gói hội viên
	- Input: không
	- Output: void
	- Gọi: `_paymentApiService.unsubscribe(token)`

**Service**: `PaymentApiService`

**`getSubscriptionInfo`**: lấy thông tin subscription
	- Input: token: String
	- Output: SubscriptionInfo {planName: String, status: String, nextBillingDate: String, price: int, timeUnit: String, billingHistory: List<SubscriptionHistoryItem>}
	- Gọi API ngoài: `GET /subscription`

**`unsubscribe`**: hủy subscription
	- Input: token: String
	- Output: void
	- Gọi API ngoài: `DELETE /subscription`

### Backend

**Tầng Controller** — `SubscriptionController`

**`getSubscriptionInfo`**: trả thông tin hội viên
	- Input: không (email từ SecurityContext)
	- Output: ApiResponse<SubscriptionInfoResponse>

**Tầng Service** — `SubscriptionServiceImpl`

**`getSubscriptionInfo`**: tổng hợp thông tin subscription
	- Input: không
	- Output: SubscriptionInfoResponse {planName: String, status: String, nextBillingDate: LocalDate, price: Long, timeUnit: String, billingHistory: List<SubscriptionHistoryItemResponse>}
	- Xử lý:
		1. `clientRepository.findByEmailAndActive(email, true)` → Client
		2. `subscriptionRepository.findHistoryByClientId(clientId)` → lịch sử
		3. `subscriptionRepository.findLatestActiveValidSubscription(clientId)` → subscription hiện tại (nếu không có: status="CHUA_DANG_KY")
		4. Tính `nextBillingDate`: MONTHS → `startAt.plusMonths(1)`, YEARS → `startAt.plusYears(1)`

**Tầng Repository** — `SubscriptionRepository`

**`findHistoryByClientId`**: lấy toàn bộ lịch sử subscription
	- Input: clientId: Long
	- Output: List<Subscription>
	- Query: `SELECT s.* FROM subscription s WHERE s.client_id = :clientId ORDER BY s.start_at DESC`

**`findLatestActiveValidSubscription`**: tìm subscription active còn hiệu lực
	- Input: clientId: Long
	- Output: Optional<Subscription>
	- Query: `SELECT s.* FROM subscription s JOIN plan p ... WHERE s.client_id = :clientId AND s.status = 'ACTIVE' AND (DATE_ADD(s.start_at, INTERVAL ...)) > NOW() ORDER BY s.start_at DESC LIMIT 1`

---

**Tầng Controller** — `SubscriptionController`

**`unsubscribe`**: hủy subscription
	- Input: không (email từ SecurityContext)
	- Output: ApiResponse<void>

**Tầng Service** — `SubscriptionServiceImpl`

**`unsubscribe`**: set status=CANCELED
	- Input: không
	- Output: void
	- Xử lý: `clientRepository.findByEmailAndActive(email, true)` → `subscriptionRepository.findLatestActiveValidSubscription(clientId)` → set status=CANCELED → `subscriptionRepository.save()`

---

## 3.10. Chức năng mua thêm credit

### Mobile App

**Màn hình**: `lib/src/payment/screens/buy_credit_screen.dart`

**`_seedDefaults`**: tải credit plan và kiểm tra premium
	- Input: không
	- Output: void
	- Gọi: `_authApiService.getCurrentUser(token)` (kiểm tra tier=PREMIUM) + `_planApiService.getCreditPlans(token)`

**`_payWithStripe`**: thực hiện mua credit
	- Input: selectedPlan: CreditPlanModel, paymentMethod: String
	- Output: void
	- Xử lý:
		1. `createCreditPurchaseIntent(...)` → `clientSecret`
		2. `Stripe.instance.initPaymentSheet(...)` + `presentPaymentSheet()`
		3. `waitForPaymentStatus(token, paymentId)`
		4. Nếu SUCCESS: `confirmCreditPurchase(token, paymentId)`
		5. `_refreshCurrentUser(token)`

**Service**: `PlanApiService`

**`getCreditPlans`**: lấy danh sách gói credit
	- Input: token: String
	- Output: List<CreditPlanModel> [{id: int, name: String, amount: String, price: int}]
	- Gọi API ngoài: `GET /credit-plan`

**Service**: `PaymentApiService`

**`createCreditPurchaseIntent`**: tạo Stripe intent cho credit
	- Input: token: String, creditPlanId: int, paymentMethod: String, idempotencyKey: String
	- Output: CreateStripeIntentResponse {paymentId: int, stripePaymentIntentId: String, clientSecret: String}
	- Gọi API ngoài: `POST /credit-plan/purchase-intent`, body: `{creditPlanId, paymentMethod, idempotencyKey}`

**`confirmCreditPurchase`**: xác nhận mua credit
	- Input: token: String, paymentId: int
	- Output: PaymentDetailResponse
	- Gọi API ngoài: `POST /credit-plan/purchase-confirm`, body: `{paymentId}`

### Backend

**Tầng Controller** — `CreditPlanController`

**`getPlans`**: trả danh sách credit plan
	- Input: không
	- Output: ApiResponse<List<CreditPlan>>

**Tầng Service** — `CreditPlanServiceImpl`

**`getPlan`**: truy vấn toàn bộ CreditPlan
	- Input: không
	- Output: List<CreditPlan> [{id: Long, name: String, amount: String, price: Long}]

**Tầng Repository** — `CreditPlanRepository`

**`findAll`**: lấy toàn bộ credit plan (kế thừa `JpaRepository`)
	- Input: không
	- Output: List<CreditPlan>

---

**Tầng Controller** — `CreditPlanController`

**`createPurchaseIntent`**: tạo Stripe intent cho credit
	- Input: request: CreateCreditPurchaseIntentRequest {creditPlanId: Long, paymentMethod: String, idempotencyKey: String}
	- Output: ApiResponse<CreateStripeIntentResponse>

**Tầng Service** — `CreditPlanServiceImpl`

**`createPurchaseIntent`**: tạo intent (chỉ premium)
	- Input: request: CreateCreditPurchaseIntentRequest
	- Output: CreateStripeIntentResponse {paymentId: Long, stripePaymentIntentId: String, clientSecret: String}
	- Xử lý:
		1. `clientRepository.findByEmailAndActive(email, true)` → Client
		2. `clientRepository.isSubscriptionActiveRaw(clientId)` — nếu != 1 → FORBIDDEN
		3. `creditPlanRepository.findById(creditPlanId)` → CreditPlan
		4. Tạo `CreateStripeIntentRequest` (orderId = "CREDIT_{clientId}_{planId}_{uuid8}", amount = creditPlan.price, currency = "vnd") → `paymentService.createStripeIntent()`

**Tầng Repository** — `CreditPlanRepository`

**`findById`**: tìm credit plan theo id (kế thừa `JpaRepository`)
	- Input: id: Long
	- Output: Optional<CreditPlan>

---

**Tầng Controller** — `CreditPlanController`

**`confirmPurchase`**: xác nhận mua credit
	- Input: request: ConfirmCreditPurchaseRequest {paymentId: Long}
	- Output: ApiResponse<void>

**Tầng Service** — `CreditPlanServiceImpl`

**`confirmPurchase`**: cộng credit vào tài khoản
	- Input: request: ConfirmCreditPurchaseRequest {paymentId: Long}
	- Output: void
	- Xử lý:
		1. Lấy Client + kiểm tra premium
		2. `paymentTransactionRepository.findById(paymentId)` → validate: thuộc user, status=SUCCESS
		3. Idempotent: `creditTransactionRepository.findByPaymentTransactionId(paymentId)` → nếu có rồi → return
		4. Map payment.amount → CreditPlan (khớp price) → regex `\d+` trích xuất số credit
		5. Tạo `CreditTransaction` (client, creditPlan, paymentTransaction, status=ACTIVE) → `creditTransactionRepository.save()`
		6. `client.totalCredit += creditsToAdd` → `clientRepository.save(client)`

**Tầng Repository** — `CreditTransactionRepository` (`client/repository/CreditTransactionRepository.java`)

**`findByPaymentTransactionId`**: kiểm tra idempotent
	- Input: paymentTransactionId: Long
	- Output: Optional<CreditTransaction>

### API ngoài

| Mô tả | Phương thức | Endpoint | Request | Response |
|-------|-------------|----------|---------|----------|
| Tạo Stripe PaymentIntent | POST | `https://api.stripe.com/v1/payment_intents` | amount, currency, payment_method_types, idempotency_key | PaymentIntent {id, client_secret} |

Gọi qua `StripePaymentClient` → Stripe Java SDK.
# 4. HƯỚNG DẪN CHẠY HỆ THỐNG

## 4.1. Yêu cầu môi trường

| Thành phần | Phiên bản | Ghi chú |
|------------|-----------|---------|
| Docker | 24+ | Chạy MySQL, Redis, Backend API |
| Docker Compose | 2+ | Orchestrate multi-container |
| Stripe CLI | Mới nhất | Webhook listener cho thanh toán |
| Ngrok | Mới nhất | Expose backend ra internet (cần tài khoản) |
| Flutter SDK | 3.0+ | Build mobile app |
| Android Studio | Mới nhất | Android emulator hoặc build APK |
| Xcode | Mới nhất | (Nếu build iOS) |

## 4.2. Backend (Docker)

### Bước 1: Cấu hình biến môi trường

Tạo file `.env` tại `api/audio-book/` với nội dung:

```
SERVER_PORT=8080
SERVER_ADDRESS=0.0.0.0

DB_URL=jdbc:mysql://host.docker.internal:3306/audio_book?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=Asia/Ho_Chi_Minh
DB_USERNAME=root
DB_PASSWORD=<YOUR_DB_PASSWORD>

REDIS_HOST=host.docker.internal
REDIS_PORT=6379

MAIL_USERNAME=<YOUR_GMAIL>
MAIL_PASSWORD=<YOUR_GMAIL_APP_PASSWORD>

JWT_SECRET=<YOUR_256_BIT_SECRET>
JWT_EXPIRATION=86400000

GOOGLE_OAUTH_CLIENT_ID=<YOUR_GOOGLE_CLIENT_ID>

AWS_ACCESS_KEY=<YOUR_AWS_ACCESS_KEY>
AWS_SECRET_KEY=<YOUR_AWS_SECRET_KEY>
AWS_REGION=ap-southeast-2
AWS_BUCKET_NAME=<YOUR_BUCKET_NAME>

STRIPE_SECRET_KEY=sk_test_xxxxxxxxxxxx
STRIPE_WEBHOOK_SECRET=whsec_xxxxxxxxxxxx
```

### Bước 2: Khởi động toàn bộ backend

```bash
cd api/audio-book
docker compose up -d --build
```

File `docker-compose.yml` định nghĩa 3 service trong cùng 1 file:

- **mysql**: image `mysql:8.0`, port 3306, database `audio_book`, password lấy từ `.env`, persistent volume `mysql_data`, healthcheck
- **redis**: image `redis:7-alpine`, port 6379, healthcheck
- **api**: build từ `Dockerfile`, port 8080, đọc biến môi trường từ `.env`, `extra_hosts` để `host.docker.internal` trỏ về host (cho MySQL/Redis)

`Dockerfile` (multi-stage):
- **Stage 1 (build)**: `maven:3.9.9-eclipse-temurin-21` — copy `pom.xml`, download dependencies, copy `src`, build `.jar` (bỏ qua test)
- **Stage 2 (runtime)**: `eclipse-temurin:21-jre-alpine` — copy `.jar` từ stage 1, expose port 8080

Backend API chạy trên `http://localhost:8080`.

### Bước 4: Chạy Stripe webhook listener (cửa sổ terminal riêng)

```bash
stripe login
stripe listen --forward-to localhost:8080/api/payments/stripe/webhook
```

Copy `webhook signing secret` từ output, cập nhật `STRIPE_WEBHOOK_SECRET` trong `.env`.

### Bước 5: Chạy Ngrok (cửa sổ terminal riêng)

```bash
ngrok http 8080
```

Copy Forwarding URL (dạng `https://xxxx-xx-xx-xxx-xx.ngrok-free.app`).

## 4.3. Mobile App

### Bước 1: Cập nhật API endpoint

Mở `mobile_client/lib/src/core/config/app_config.dart`. Thay `_deviceBaseUrl` bằng Ngrok URL + `/api`:

```dart
static const String _deviceBaseUrl = String.fromEnvironment(
  'API_DEVICE_BASE_URL',
  defaultValue: 'https://YOUR_NGROK_URL.ngrok-free.app/api',
);
```

Hoặc truyền qua `--dart-define`:

```bash
flutter run --dart-define=API_BASE_URL=https://YOUR_NGROK_URL.ngrok-free.app/api
```

### Bước 2: Cấu hình Google Sign-In

Mở `mobile_client/lib/src/auth/services/google_auth_service.dart`. Thay `_webClientId`.

### Bước 3: Cài đặt dependencies và chạy

```bash
cd mobile_client
flutter pub get
flutter run
```

Build APK (Android):

```bash
flutter build apk --dart-define=API_BASE_URL=https://YOUR_NGROK_URL.ngrok-free.app/api
```

## 4.4. Thứ tự khởi động khuyến nghị

| Bước | Thành phần | Lệnh |
|------|------------|------|
| 1 | Backend (MySQL + Redis + API) | `cd api/audio-book && docker compose up -d --build` |
| 3 | Stripe CLI | `stripe listen --forward-to localhost:8080/api/payments/stripe/webhook` |
| 4 | Ngrok | `ngrok http 8080` → copy URL |
| 5 | Mobile App | `cd mobile_client && flutter run --dart-define=API_BASE_URL=<NGROK_URL>/api` |

---