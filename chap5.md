# 5. CÂY THƯ MỤC DỰ ÁN

## 5.1. Tổng quan

```
AudioBook/
├── api/                               # Backend Spring Boot
│   └── audio-book/
│       ├── Dockerfile
│       ├── docker-compose.yml
│       ├── .env
│       ├── pom.xml
│       └── src/main/java/org/backend/
│           ├── Application.java
│           ├── auth/                   # Xác thực (controller, service, dto)
│           ├── client/                 # Người dùng, subscription, credit
│           ├── config/                 # Security, Redis, S3, JPA
│           ├── common/                 # Exception handler, ApiResponse, JWT utils
│           ├── user/                   # Entity User nền tảng
│           ├── payment/                # Thanh toán Stripe
│           └── file/                   # Quản lý file upload S3
│
└── mobile_client/                      # Flutter App
    ├── pubspec.yaml
    └── lib/
        ├── main.dart
        └── src/
            ├── auth/                   # Xác thực (screens, services, models)
            ├── profile/screens/        # Quản lý cá nhân
            ├── payment/                # Thanh toán & credit
            ├── core/                   # Config, utils, widgets
            ├── home/screens/           # Màn hình chính
            └── util/routes.dart        # Định tuyến
```

## 5.2. Backend (`api/audio-book/`)

```
api/audio-book/
├── Dockerfile                           # Multi-stage: Maven build → JRE runtime
├── docker-compose.yml                   # MySQL 8.0 + Redis 7 + API (dùng chung .env)
├── .env                                 # Biến môi trường (DB, Redis, Mail, JWT, Stripe, AWS)
├── pom.xml                              # Maven: Spring Boot, JPA, Security, Stripe, JWT, ...
│
└── src/main/java/org/backend/
    ├── Application.java                 # Entry point @SpringBootApplication
    │
    ├── auth/                            # ═══ Xác thực ═══
    │   ├── controller/
    │   │   └── AuthController.java      # /auth/login, /auth/login/google, /auth/otp/verify,
    │   │                                   /auth/active, /auth/forgot-password, /auth/reset-password,
    │   │                                   /auth/change-password, /auth/logout
    │   ├── dto/request/
    │   │   ├── LoginRequest.java            # email, password
    │   │   ├── GoogleLoginRequest.java      # idToken
    │   │   ├── OtpRequest.java              # email
    │   │   ├── VerifyOtpRequest.java        # email, otp, otpPurpose
    │   │   ├── ResetPasswordRequest.java    # password
    │   │   └── ChangePasswordRequest.java   # oldPassword, newPassword
    │   ├── dto/response/
    │   │   └── TokenResponse.java           # token, userInfo
    │   ├── enums/
    │   │   └── OtpPurpose.java              # VERIFY_EMAIL, RESET_PASSWORD
    │   └── service/impl/
    │       └── AuthServiceImpl.java         # login, loginWithGoogle, verifyOtp, activeAccount,
    │                                           forgotPassword, resetPassword, changePassword, logout
    │
    ├── client/                           # ═══ Người dùng + Subscription + Credit ═══
    │   ├── controller/
    │   │   ├── ClientController.java         # /client/register, /client/me, /client/change-name,
    │   │   │                                    /client/email/pre-change, /client/email/change,
    │   │   │                                    /client/avatar/change
    │   │   ├── PlanController.java           # /plans (danh sách gói hội viên)
    │   │   ├── SubscriptionController.java   # /subscription (GET info, POST subscribe, DELETE unsubscribe)
    │   │   └── CreditPlanController.java     # /credit-plan (GET list, POST purchase-intent, POST purchase-confirm)
    │   ├── dto/request/
    │   │   ├── RegisterRequest.java              # name, email, password
    │   │   ├── ChangeNameRequest.java            # name
    │   │   ├── ChangeEmailRequest.java           # newEmail, otp
    │   │   ├── PreChangeEmailRequest.java        # newEmail
    │   │   ├── UpPremiumRequest.java             # planId, paymentId
    │   │   ├── CreateCreditPurchaseIntentRequest.java  # creditPlanId, paymentMethod, idempotencyKey
    │   │   └── ConfirmCreditPurchaseRequest.java # paymentId
    │   ├── dto/response/
    │   │   ├── ClientResponse.java              # id, name, email, role, tier, avatarUrl, totalCredit
    │   │   ├── PlanResponse.java                # id, name, price, timeUnit
    │   │   ├── SubscriptionInfoResponse.java    # planName, status, nextBillingDate, price, billingHistory[]
    │   │   └── SubscriptionHistoryItemResponse.java  # planName, price, startDate, status
    │   ├── entity/
    │   │   ├── Client.java                 # extends User: totalCredit, subscriptions, creditTransactions
    │   │   ├── Plan.java                   # name, price, timeUnit (MONTHS/YEARS)
    │   │   ├── Subscription.java           # client, plan, paymentTransaction, startAt, status
    │   │   ├── CreditPlan.java             # name, amount (vd: "50 Credits"), price
    │   │   └── CreditTransaction.java      # client, creditPlan, paymentTransaction, status
    │   ├── enums/
    │   │   ├── Status.java                 # ACTIVE, CANCELED
    │   │   ├── Tier.java                   # BASE, PREMIUM
    │   │   └── TimeUnit.java               # MONTHS, YEARS
    │   ├── mapper/
    │   │   └── ClientMapper.java           # MapStruct: Entity ↔ ClientResponse
    │   ├── repository/
    │   │   ├── ClientRepository.java           # findByEmail, findByEmailAndActive, isSubscriptionActiveRaw
    │   │   ├── PlanRepository.java             # findAll
    │   │   ├── SubscriptionRepository.java     # findHistoryByClientId, findLatestActiveValidSubscription
    │   │   ├── CreditPlanRepository.java       # findAll
    │   │   └── CreditTransactionRepository.java  # findByPaymentTransactionId
    │   └── service/impl/
    │       ├── ClientServiceImpl.java          # register, me, changeName, changeEmail, changeAvatar
    │       ├── PlanServiceImpl.java            # getAllPlans
    │       ├── SubscriptionServiceImpl.java    # subscribe, unsubscribe, getSubscriptionInfo
    │       └── CreditPlanServiceImpl.java      # getPlan, createPurchaseIntent, confirmPurchase
    │
    ├── config/                            # ═══ Cấu hình ═══
    │   ├── security/
    │   │   ├── SecurityConfig.java        # PUBLIC_ENDPOINT, CORS, BCrypt(12)
    │   │   ├── JwtFilter.java             # OncePerRequestFilter: validate JWT, check Redis blacklist
    │   │   └── AuthEntryPoint.java        # 401 handler
    │   ├── RedisConfig.java               # RedisTemplate
    │   ├── S3Config.java                  # AWS S3 client
    │   ├── EntityAuditingConfig.java      # JPA auditing
    │   └── SwaggerConfig.java             # OpenAPI docs
    │
    ├── common/                            # ═══ Tiện ích chung ═══
    │   ├── exception/
    │   │   ├── BusinessException.java     # Runtime exception bọc ErrorCode
    │   │   ├── ErrorCode.java             # Enum mã lỗi (1001-20000) + message + HTTP status
    │   │   └── GlobalExceptionHandler.java  # @RestControllerAdvice
    │   ├── response/
    │   │   └── ApiResponse.java           # code, message, data
    │   └── util/
    │       ├── JwtUtil.java               # generateToken, validateToken, getClaims
    │       ├── OtpCodeUtil.java           # generateOtpCode() → 6 chữ số
    │       └── EmailUtil.java             # sendOtpEmail(email, otp, subject, body, ttlMinutes)
    │
    ├── user/                              # ═══ Entity nền tảng ═══
    │   ├── entity/User.java               # id, email, password, name, role, active, avatarFile
    │   ├── enums/RoleEnum.java            # USER, ADMIN
    │   ├── mapper/UserMapper.java         # Entity → UserInfo DTO
    │   ├── repository/UserRepository.java # findByEmail, findByEmailAndActive, existsByEmail...
    │   └── service/impl/UserServiceImpl.java  # UserDetailsService.loadUserByUsername
    │
    ├── payment/                           # ═══ Thanh toán Stripe ═══
    │   ├── controller/PaymentController.java     # /payments/stripe/create-intent, webhook, /payments/{id}
    │   ├── entity/PaymentTransaction.java        # paymentCode, orderId, userId, amount, currency, status,
    │   │                                             stripePaymentIntentId, stripeClientSecret
    │   ├── enums/
    │   │   ├── PaymentMethod.java                # CARD
    │   │   ├── PaymentProvider.java              # STRIPE
    │   │   └── PaymentStatus.java                # PENDING, SUCCESS, FAILED, CANCELED
    │   └── service/impl/PaymentServiceImpl.java  # createStripeIntent, handleWebhook, getPaymentDetail
    │
    └── file/                              # ═══ Quản lý file ═══
        ├── controller/FileController.java # /files/upload (multipart, S3)
        ├── entity/File.java               # fileName, filePath, fileType
        └── repository/FileRepository.java
```

## 5.3. Mobile App (`mobile_client/`)

```
mobile_client/
├── pubspec.yaml                             # Flutter config: http, provider, flutter_stripe, google_sign_in, ...
│
└── lib/
    ├── main.dart                            # Entry point: Stripe.init, MaterialApp, theme, initialRoute
    │
    └── src/
        ├── auth/                            # ═══ Xác thực ═══
        │   ├── models/
        │   │   ├── api_response.dart            # ApiResponse<T>: code, message, data
        │   │   ├── login_request.dart            # email, password
        │   │   ├── register_request.dart         # name, email, password
        │   │   ├── token_response.dart           # token, userInfo
        │   │   ├── user_info.dart                # id, name, email, role, tier, avatarUrl, totalCredit
        │   │   ├── otp_request.dart              # email
        │   │   ├── otp_purpose.dart              # Enum: verifyEmail, resetPassword
        │   │   ├── verify_otp_request.dart       # email, otp, otpPurpose
        │   │   ├── verify_otp_args.dart          # Arguments truyền giữa màn hình
        │   │   ├── recover_password_args.dart    # Arguments cho recover password
        │   │   ├── change_password_request.dart  # oldPassword, newPassword
        │   │   ├── reset_password_request.dart   # password
        │   │   └── avatar_file.dart              # id, filePath
        │   ├── screens/
        │   │   ├── login_screen.dart             # Đăng nhập email/password + Google
        │   │   ├── register_screen.dart          # Đăng ký tài khoản mới
        │   │   ├── verify_otp_screen.dart         # Nhập OTP xác thực email
        │   │   ├── forgot_password_screen.dart    # Quên mật khẩu (nhập email nhận OTP)
        │   │   └── recover_password_screen.dart   # Đặt lại mật khẩu (OTP + password mới)
        │   └── services/
        │       ├── auth_api_service.dart         # HTTP client: login, register, OTP, profile, changePassword, ...
        │       ├── google_auth_service.dart      # Google Sign-In: signIn, getIdToken, signOut
        │       └── token_storage_service.dart    # SharedPreferences: saveAuthSession, getToken, clearToken
        │
        ├── profile/screens/                 # ═══ Quản lý cá nhân ═══
        │   ├── profile_screen.dart              # Thông tin + menu + đổi avatar + đăng xuất
        │   ├── change_username_screen.dart      # Đổi tên hiển thị
        │   ├── change_email_screen.dart         # Đổi email (bước 1: nhập email mới, bước 2: nhập OTP)
        │   ├── change_password_screen.dart      # Đổi mật khẩu (oldPassword + newPassword)
        │   ├── premium_plan_screen.dart         # Chọn gói hội viên + thanh toán Stripe
        │   └── subscription_screen.dart         # Thông tin hội viên + lịch sử + hủy gói
        │
        ├── payment/                         # ═══ Thanh toán & Credit ═══
        │   ├── models/
        │   │   ├── plan.dart                    # PlanModel: id, name, price, timeUnit
        │   │   ├── credit_plan.dart             # CreditPlanModel: id, name, amount, price
        │   │   ├── payment_models.dart          # CreateStripeIntentResponse, PaymentDetailResponse, ...
        │   │   └── subscription_info.dart       # SubscriptionInfo + SubscriptionHistoryItem
        │   ├── screens/
        │   │   └── buy_credit_screen.dart       # Mua credit (chặn nếu không phải premium)
        │   └── services/
        │       ├── payment_api_service.dart     # Stripe intent, poll status, subscribe, unsubscribe, credit
        │       └── plan_api_service.dart        # getPlans, getCreditPlans
        │
        ├── core/                            # ═══ Cấu hình & Tiện ích ═══
        │   ├── config/
        │   │   └── app_config.dart              # Base URL (Ngrok), Android emulator toggle
        │   ├── utils/
        │   │   └── error_translator.dart        # Dịch lỗi Anh → Việt (~70 mục)
        │   └── widgets/
        │       └── form_error_widget.dart       # Widget hiển thị lỗi dưới ô input
        │
        ├── home/screens/
        │   └── discovery_screen.dart        # Màn hình chính (khám phá sách)
        │
        └── util/
            └── routes.dart                  # Định tuyến tập trung: AppRoutes + generateRoute
