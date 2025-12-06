import Foundation
// 서버 응답 형태에 맞춘 구조체
struct LoginResponseDTO: Decodable {
    let accessToken: String
    let refreshToken: String
    let userId: Int        // 서버가 Long이면 Swift에서는 Int 또는 Int64
    let nickname: String?  // 닉네임도 온다면 추가
}
class AuthAPI {
    static let shared = AuthAPI()
    private init() {}

    // 현재 Access Token (Keychain에서 읽기)
    var currentAccessToken: String? {
        return KeychainManager.get(key: "accessToken")
    }

    // 현재 로그인한 사용자 아이디 (users.user_id 컬럼 값, 즉 로그인 ID)
    var currentLoginUserId: String? {
        get { UserDefaults.standard.string(forKey: "userId") }
        set { UserDefaults.standard.setValue(newValue, forKey: "userId") }
    }

    // 🔥 디버그/릴리즈 자동 전환
    private let baseURL: String = {
        #if DEBUG
        return "http://127.0.0.1:8080/api/auth"   // 로컬 스프링부트
        #else
        return "http://13.124.208.108:8080/api/auth"   // 배포 서버
        #endif
    }()

    // MARK: - Logging Helper

    private func log(_ message: String) {
        print("📘 [AuthAPI] \(message)")
    }

    private func logRequest(url: URL, body: Data?) {
        log("➡️ Request URL: \(url.absoluteString)")
        if let body = body, let json = String(data: body, encoding: .utf8) {
            log("📤 Request Body: \(json)")
        }
    }

    private func logResponse(data: Data, response: URLResponse?) {
        if let http = response as? HTTPURLResponse {
            log("⬅️ Status Code: \(http.statusCode)")
        }

        if let raw = String(data: data, encoding: .utf8) {
            log("📄 Response Raw: \(raw)")
        } else {
            log("⚠️ Response Raw: <Non-UTF8 Data>")
        }
    }

    private func makeJSONRequest(url: URL, body: Data) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        return request
    }

    // MARK: - Login

    /// 로그인: /api/auth/login
    /// 서버 DTO: LoginRequest { userId, password }
    // MARK: - Login

    /// 로그인: /api/auth/login
    /// 서버 DTO: LoginRequest { userId, password }
    func login(id: String, password: String) async throws -> LoginResponse {
            guard let url = URL(string: "\(baseURL)/login") else {
                throw URLError(.badURL)
            }

            let bodyDict: [String: String] = [
                "userId": id,        // 🔹 서버 DTO LoginRequest.userId
                "password": password
            ]
            let jsonBody = try JSONSerialization.data(withJSONObject: bodyDict, options: [])

            var request = makeJSONRequest(url: url, body: jsonBody)
            logRequest(url: url, body: jsonBody)

            let (data, response) = try await URLSession.shared.data(for: request)
            logResponse(data: data, response: response)

            guard let http = response as? HTTPURLResponse else {
                throw URLError(.badServerResponse)
            }

            guard (200..<300).contains(http.statusCode) else {
                if let raw = String(data: data, encoding: .utf8) {
                    log("❌ Login HTTP \(http.statusCode), body=\(raw)")
                }
                throw NSError(
                    domain: "LoginError",
                    code: http.statusCode,
                    userInfo: [NSLocalizedDescriptionKey: "로그인에 실패했습니다. (code \(http.statusCode))"]
                )
            }

            let res = try JSONDecoder().decode(LoginResponse.self, from: data)
        //  // 3. 🚨 [핵심 수정] Data를 구조체로 변환 (Decode)
        // 여기서 'response' 변수가 아니라, 위에서 정의한 'LoginResponseDTO'로 변환해야 합니다.
        let decodedResponse = try JSONDecoder().decode(LoginResponseDTO.self, from: data)
        
        // 4. ✅ 변환된 객체에서 토큰 꺼내서 저장
        UserDefaults.standard.set(decodedResponse.accessToken, forKey: "accessToken")
        UserDefaults.standard.set(decodedResponse.refreshToken, forKey: "refreshToken")
        UserDefaults.standard.set(String(decodedResponse.userId), forKey: "userId")
            // ✅ 토큰/유저 정보 저장 (다른 코드에 영향 없이 기존 키만 사용)
            KeychainManager.save(key: "accessToken", value: res.accessToken)
            KeychainManager.save(key: "refreshToken", value: res.refreshToken)

            // 로그인 ID는 사용자가 입력한 id 그대로 저장
            self.currentLoginUserId = id
            UserDefaults.standard.setValue(res.nickname, forKey: "nickname")
        // 🔹 userId 저장
        UserDefaults.standard.setValue(res.userId, forKey: "userId")

            return res
        }



    // MARK: - Signup

    /// 회원가입: /api/auth/signup
    /// 서버 DTO: SignupRequest { userId, password, nickname, email }
    func signup(
        id: String,
        password: String,
        nickname: String,
        email: String
    ) async throws {

        guard let url = URL(string: "\(baseURL)/signup") else { throw URLError(.badURL) }

        let body = SignupRequestDTO(
            userId: id,
            password: password,
            nickname: nickname,
            email: email
        )
        let jsonBody = try JSONEncoder().encode(body)

        let request = makeJSONRequest(url: url, body: jsonBody)
        logRequest(url: url, body: jsonBody)

        let (data, response) = try await URLSession.shared.data(for: request)
        logResponse(data: data, response: response)

        guard let httpRes = response as? HTTPURLResponse,
              (200..<300).contains(httpRes.statusCode) else {
            throw NSError(
                domain: "SignupError",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "회원가입 요청에 실패했습니다."]
            )
        }

        do {
            let res = try JSONDecoder().decode(SignupResponseDTO.self, from: data)
            // 🚨 [필수 추가] 회원가입 응답에도 토큰이 있다면 저장해야 함
                // (만약 서버가 회원가입 시엔 토큰을 안 준다면, 회원가입 후 login()을 호출해야 함)
            if let token = res.accessToken {
                UserDefaults.standard.set(token, forKey: "accessToken")
                print("✅ 회원가입 성공 & 토큰 저장 완료")
            }

            
        } catch {
            log("❌ Signup decode error: \(error.localizedDescription)")
            throw error
        }
    }

    // MARK: - Password Reset (1단계: 코드 발송)

    /// 비밀번호 재설정 코드 요청: /api/auth/reset/request
    func requestPasswordReset(userId: String) async throws -> ResetPasswordResponseDTO {
        guard let url = URL(string: "\(baseURL)/reset/request") else { throw URLError(.badURL) }

        let bodyDict = ["userId": userId]
        let jsonBody = try JSONEncoder().encode(bodyDict)

        let request = makeJSONRequest(url: url, body: jsonBody)
        logRequest(url: url, body: jsonBody)

        let (data, response) = try await URLSession.shared.data(for: request)
        logResponse(data: data, response: response)

        guard let httpRes = response as? HTTPURLResponse,
              (200..<300).contains(httpRes.statusCode) else {
            throw NSError(
                domain: "ResetError",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "비밀번호 재설정 코드 요청 실패"]
            )
        }

        let res = try JSONDecoder().decode(ResetPasswordResponseDTO.self, from: data)
        return res
    }

    // MARK: - Password Reset (2단계: 코드 + 새 비밀번호)

    /// 비밀번호 재설정 확정: /api/auth/reset/confirm
    func confirmPasswordReset(
        userId: String,
        code: String,
        newPassword: String
    ) async throws -> ResetPasswordResponseDTO {
        guard let url = URL(string: "\(baseURL)/reset/confirm") else { throw URLError(.badURL) }

        let bodyDict: [String: String] = [
            "userId": userId,
            "code": code,
            "newPassword": newPassword
        ]
        let jsonBody = try JSONEncoder().encode(bodyDict)

        let request = makeJSONRequest(url: url, body: jsonBody)
        logRequest(url: url, body: jsonBody)

        let (data, response) = try await URLSession.shared.data(for: request)
        logResponse(data: data, response: response)

        guard let httpRes = response as? HTTPURLResponse,
              (200..<300).contains(httpRes.statusCode) else {
            throw NSError(
                domain: "ResetError",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "비밀번호 재설정 실패"]
            )
        }

        let res = try JSONDecoder().decode(ResetPasswordResponseDTO.self, from: data)
        return res
    }

    // MARK: - Token Refresh

    /// 토큰 재발급: /api/auth/token/refresh
    func refreshAccessToken() async throws -> String {
        guard let url = URL(string: "\(baseURL)/token/refresh") else { throw URLError(.badURL) }

        guard let refreshToken = KeychainManager.get(key: "refreshToken"),
              !refreshToken.isEmpty else {
            throw NSError(
                domain: "TokenError",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "리프레시 토큰이 없습니다. 다시 로그인 해주세요."]
            )
        }

        let body = TokenRefreshRequestDTO(refreshToken: refreshToken)
        let jsonBody = try JSONEncoder().encode(body)

        let request = makeJSONRequest(url: url, body: jsonBody)
        logRequest(url: url, body: jsonBody)

        let (data, response) = try await URLSession.shared.data(for: request)
        logResponse(data: data, response: response)

        guard let httpRes = response as? HTTPURLResponse,
              (200..<300).contains(httpRes.statusCode) else {
            throw NSError(
                domain: "TokenError",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "토큰 재발급에 실패했습니다."]
            )
        }

        let res = try JSONDecoder().decode(TokenRefreshResponseDTO.self, from: data)

        // 새 토큰 저장
        KeychainManager.save(key: "accessToken", value: res.accessToken)
        KeychainManager.save(key: "refreshToken", value: res.refreshToken)

        return res.accessToken
    }

    // MARK: - Logout Helper

    func logout() {
        KeychainManager.delete(key: "accessToken")
        KeychainManager.delete(key: "refreshToken")
        UserDefaults.standard.removeObject(forKey: "userId")
        UserDefaults.standard.removeObject(forKey: "nickname")
    }
}
