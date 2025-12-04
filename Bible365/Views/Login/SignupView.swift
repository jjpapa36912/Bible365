import Foundation
import SwiftUI

struct SignupView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var userId: String = ""
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""

    @State private var isLoading: Bool = false
    @State private var alertMessage: String = ""
    @State private var showAlert: Bool = false

    var body: some View {
        VStack(spacing: 24) {
            Text("Sign Up")
                .font(.largeTitle.bold())
                .padding(.top, 60)

            VStack(spacing: 16) {
                TextField("ID", text: $userId)
                    .padding()
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(10)
                    .autocorrectionDisabled(true)
                    .textInputAutocapitalization(.never)

                TextField("Name", text: $name)
                    .padding()
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(10)

                TextField("Email", text: $email)
                    .padding()
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(10)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)

                SecureField("Password (8자 이상)", text: $password)
                    .padding()
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(10)

                SecureField("Confirm Password", text: $confirmPassword)
                    .padding()
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(10)
            }

            Button {
                Task { await signup() }
            } label: {
                if isLoading {
                    ProgressView()
                        .tint(.blue)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                } else {
                    Text("회원가입")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .foregroundColor(.blue)
                        .cornerRadius(12)
                }
            }
            .disabled(isLoading)

            Button {
                dismiss()
            } label: {
                Text("로그인 화면으로 돌아가기")
                    .font(.footnote)
                    .underline()
                    .foregroundColor(.white)
            }

            Spacer()
        }
        .padding(.horizontal, 30)
        .background(Color.blue.ignoresSafeArea())
        .alert("알림", isPresented: $showAlert) {
            Button("확인") {
                if alertMessage == "회원가입이 완료되었습니다." {
                    dismiss()
                }
            }
        } message: {
            Text(alertMessage)
        }
        .navigationBarBackButtonHidden(true)
    }

    // MARK: - Signup Logic

    func signup() async {
        guard !userId.isEmpty,
              !email.isEmpty,
              !name.isEmpty,
              !password.isEmpty,
              !confirmPassword.isEmpty else {
            showAlert("모든 필드를 입력해주세요.")
            return
        }

        guard email.contains("@"), email.contains(".") else {
            showAlert("올바른 이메일 주소를 입력해주세요.")
            return
        }

        guard password.count >= 8 else {
            showAlert("비밀번호는 8자 이상이어야 합니다.")
            return
        }

        guard password == confirmPassword else {
            showAlert("비밀번호가 일치하지 않습니다.")
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            try await AuthAPI.shared.signup(
                id: userId,
                password: password,
                nickname: name,
                email: email
            )

            showAlert("회원가입이 완료되었습니다.")
        } catch {
            showAlert(error.localizedDescription.isEmpty ? "회원가입에 실패했습니다." : error.localizedDescription)
        }
    }

    private func showAlert(_ msg: String) {
        alertMessage = msg
        showAlert = true
    }
}
