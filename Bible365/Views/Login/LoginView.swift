import SwiftUI

struct LoginView: View {
    @State private var userId: String = ""
    @State private var password: String = ""

    // 🔹 알림 상태
    @State private var showAlert: Bool = false
    @State private var alertTitle: String = "알림"
    @State private var alertMessage: String = ""

    // 🔹 부모에서 주입하는 콜백들
    var onLoginSuccess: (() -> Void)? = nil
    var onSignupTapped: (() -> Void)? = nil
    var onFindPasswordTapped: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 30) {
            Text("Log In")
                .font(.largeTitle)
                .bold()
                .padding(.top, 80)

            TextField("ID", text: $userId)
                .padding()
                .background(Color.white.opacity(0.2))
                .cornerRadius(10)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)

            SecureField("Password", text: $password)
                .padding()
                .background(Color.white.opacity(0.2))
                .cornerRadius(10)

            Button("Log In") {
                Task {
                    // 🔹 간단한 입력 체크
                    guard !userId.isEmpty, !password.isEmpty else {
                        alertTitle = "알림"
                        alertMessage = "ID와 비밀번호를 모두 입력해주세요."
                        showAlert = true
                        return
                    }

                    do {
                        // 🔹 실제 로그인 API 호출
                        let response: LoginResponse = try await AuthAPI.shared.login(id: userId, password: password)
                        AuthManager.shared.applyLogin(response: response)
                        onLoginSuccess?()
                        print("🔑 ACCESS TOKEN =", AuthAPI.shared.currentAccessToken ?? "nil")

                        // 🔹 로그인 성공 시 콜백
                        onLoginSuccess?()
                    } catch {
                        print("Login failed:", error.localizedDescription)
                        alertTitle = "로그인 실패"
                        alertMessage = error.localizedDescription.isEmpty
                            ? "ID 또는 비밀번호가 올바르지 않습니다."
                            : error.localizedDescription
                        showAlert = true
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.white)
            .foregroundColor(.blue)
            .cornerRadius(12)

            HStack(spacing: 24) {
                Button {
                    onFindPasswordTapped?()
                } label: {
                    Text("비밀번호 찾기")
                        .font(.footnote)
                        .underline()
                        .foregroundColor(.white)
                }

                Button {
                    onSignupTapped?()
                } label: {
                    Text("회원가입")
                        .font(.footnote)
                        .underline()
                        .foregroundColor(.white)
                }
            }
            .padding(.top, 4)

            Spacer()
        }
        .padding(.horizontal, 30)
        .background(Color.blue.ignoresSafeArea())
        .alert(alertTitle, isPresented: $showAlert) {
            Button("확인", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
}
