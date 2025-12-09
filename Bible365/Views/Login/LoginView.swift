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

            Button(action: {
                Task {
                    guard !userId.isEmpty, !password.isEmpty else {
                        alertTitle = "알림"
                        alertMessage = "ID와 비밀번호를 모두 입력해주세요."
                        showAlert = true
                        return
                    }

                    do {
                        let response: LoginResponse = try await AuthAPI.shared.login(id: userId, password: password)
                        AuthManager.shared.applyLogin(response: response)
                        onLoginSuccess?()
                    } catch {
                        alertTitle = "로그인 실패"
                        alertMessage = error.localizedDescription.isEmpty
                            ? "ID 또는 비밀번호가 올바르지 않습니다."
                            : error.localizedDescription
                        showAlert = true
                    }
                }
            }) {
                Text("Log In")
                    .frame(maxWidth: .infinity)   // ← 가로는 꽉 채움
                    .padding(.vertical, 12)       // ← 자연스러운 버튼 높이
                    .background(Color.white)
                    .foregroundColor(.blue)
                    .cornerRadius(12)
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
