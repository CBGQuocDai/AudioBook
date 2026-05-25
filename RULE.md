RULE VẼ RECURSIVE / SELF-CALL CHUẨN

1. Recursive self-call dùng để thể hiện một lifeline đang tự thực thi method của chính nó.

2. Khi object nhận lời gọi từ object khác, nếu method đó có xử lý logic đáng biểu diễn, phải vẽ theo mẫu:

   A -> B: n: method(args)
   activate B

   B -> B: n+1: method()
   activate B
   deactivate B

3. Activation chính của B không được tắt ngay sau self-call.
   Self-call chỉ kết thúc method nội bộ, còn B vẫn đang giữ quyền xử lý để gọi dependency tiếp theo hoặc trả kết quả.

4. Mẫu đúng:

   LoginScreen -> AuthApiService: 3: login(LoginRequest)
   activate AuthApiService

   AuthApiService -> AuthApiService: 4: login()
   activate AuthApiService
   deactivate AuthApiService

   AuthApiService -> AuthController: 5: POST /auth/login
   activate AuthController

   AuthController --> AuthApiService: 6: ApiResponse
   deactivate AuthController

   AuthApiService --> LoginScreen: 7: ApiResponse
   deactivate AuthApiService

5. Mẫu sai:

   LoginScreen -> AuthApiService: 3: login(LoginRequest)
   activate AuthApiService

   AuthApiService -> AuthApiService: 4: login()
   deactivate AuthApiService

   AuthApiService -> AuthController: 5: POST /auth/login

   Sai vì deactivate AuthApiService quá sớm.

6. Với self-call, luôn dùng cặp activate/deactivate riêng:

   Object -> Object: n: internalMethod()
   activate Object
   deactivate Object

7. Nếu method nội bộ có gọi dependency khác, self-call có thể bao quanh toàn bộ phần dependency đó.

   Mẫu chuẩn hơn khi muốn thể hiện method đang chạy đến khi dependency trả về:

   A -> B: n: method(args)
   activate B

   B -> B: n+1: method()
   activate B

   B -> C: n+2: dependencyCall()
   activate C
   C --> B: n+3: result
   deactivate C

   deactivate B

   B --> A: n+4: response
   deactivate B

8. Khi nào dùng mẫu số 7:
   - method chính thực sự bao gồm các lời gọi dependency
   - muốn activation bar recursive kéo dài đúng phạm vi thực thi method
   - muốn biểu đồ giống Visual Paradigm hơn

9. Khi method chỉ có xử lý ngắn trước khi gọi dependency, có thể dùng mẫu ngắn:

   B -> B: prepareRequest()
   activate B
   deactivate B

   B -> C: callDependency()

10. Với hàm nghiệp vụ chính như login(), createBooking(), processPayment(),
    ưu tiên dùng mẫu recursive kéo dài bao quanh các dependency bên trong.

11. Ví dụ service nghiệp vụ:

   AuthController -> AuthServiceImpl: 8: login(LoginRequest)
   activate AuthServiceImpl

   AuthServiceImpl -> AuthServiceImpl: 9: login()
   activate AuthServiceImpl

   AuthServiceImpl -> UserRepository: 10: findByEmailAndActive(email, true)
   activate UserRepository
   UserRepository --> AuthServiceImpl: 11: User
   deactivate UserRepository

   AuthServiceImpl -> PasswordEncoder: 12: matches(rawPassword, encodedPassword)
   activate PasswordEncoder
   PasswordEncoder --> AuthServiceImpl: 13: true
   deactivate PasswordEncoder

   AuthServiceImpl -> JwtUtil: 14: generateToken(User)
   activate JwtUtil
   JwtUtil --> AuthServiceImpl: 15: token
   deactivate JwtUtil

   AuthServiceImpl -> UserMapper: 16: entityToResponse(User)
   activate UserMapper
   UserMapper --> AuthServiceImpl: 17: UserResponse
   deactivate UserMapper

   deactivate AuthServiceImpl

   AuthServiceImpl --> AuthController: 18: TokenResponse
   deactivate AuthServiceImpl

12. Lưu ý quan trọng:
    Trong ví dụ trên có 2 activation của AuthServiceImpl:
    - activation ngoài: AuthServiceImpl đang nhận quyền xử lý từ Controller
    - activation trong: method login() đang thực thi nội bộ

13. Deactivate đầu tiên của AuthServiceImpl kết thúc self-call login().
    Deactivate thứ hai của AuthServiceImpl kết thúc lifeline chính sau khi trả response.

14. Không đặt return message trước khi tắt self-call nếu method vẫn còn đang thực thi.

15. Thứ tự chuẩn:

    call external
    activate lifeline chính
    self-call method
    activate self-call
    call dependencies
    receive dependency results
    deactivate self-call
    return response
    deactivate lifeline chính

16. Với UI method như _submitLogin():

   User -> LoginScreen: 1: nhấn đăng nhập
   activate LoginScreen

   LoginScreen -> LoginScreen: 2: _submitLogin()
   activate LoginScreen

   LoginScreen -> AuthApiService: 3: login(LoginRequest)
   activate AuthApiService
   AuthApiService --> LoginScreen: 4: ApiResponse
   deactivate AuthApiService

   LoginScreen -> TokenStorageService: 5: saveAuthSession()
   activate TokenStorageService
   TokenStorageService --> LoginScreen: 6: saved
   deactivate TokenStorageService

   LoginScreen -> LoginScreen: 7: navigateByRole()
   activate LoginScreen
   deactivate LoginScreen

   deactivate LoginScreen

17. Nếu self-call là method chính của UI, có thể kéo dài self-call đến hết các bước con của UI.
    Khi đó UI có:
    - activation ngoài: màn hình đang xử lý thao tác người dùng
    - activation trong: _submitLogin() đang chạy

18. Không cần recursive cho mọi helper nhỏ.
    Chỉ dùng recursive cho method có ý nghĩa trong flow báo cáo.

19. Một diagram không nên có quá nhiều recursive self-call nhỏ.
    Ưu tiên recursive cho:
    - method entry point của mỗi layer
    - method nghiệp vụ chính
    - method lưu trữ/chuyển hướng chính

20. Rule quyết định:
    Nếu method là entry point của lifeline hoặc đại diện cho một bước xử lý chính trong use case,
    hãy vẽ recursive self-call kéo dài đến khi các dependency bên trong hoàn tất.

21. Đồng nhất message khi gọi các thành phần trong hệ thống
    - Với message đi: -> : gọi. Note nếu là call api thì ghi thêm thông tin enpoint
    - Với return : --> trả về kết quả
    - Tất cả hàm được thực thi phải đặt trong recusive : message = tên hàm