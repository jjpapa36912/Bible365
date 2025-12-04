import SwiftUI

struct FindPasswordView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var userId: String = ""
    @State private var isLoading: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertTitle: String = "알림"
    @State private var alertMessage: String = ""

    var body: some View {
        VStack(spacing: 24) {
            Text("비밀번호 찾기")
                .font(.largeTitle.bold())
                .padding(.top, 60)

            Text("가입하신 ID를 입력하시면,\n해당 계정의 이메일로 임시 비밀번호를 보내드립니다.")
                .multilineTextAlignment(.center)
                .foregroundColor(.white.opacity(0.9))

            TextField("ID", text: $userId)
                .padding()
                .background(Color.white.opacity(0.2))
                .cornerRadius(10)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)

            Button {
                Task { await requestReset() }
            } label: {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                } else {
                    Text("임시 비밀번호 받기")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .foregroundColor(.blue)
                        .cornerRadius(12)
                }
            }
            .disabled(isLoading)

            Button("로그인 화면으로 돌아가기") {
                dismiss()
            }
            .foregroundColor(.white)
            .underline()

            Spacer()
        }
        .padding(.horizontal, 30)
        .background(Color.blue.ignoresSafeArea())
        .alert(alertTitle, isPresented: $showAlert) {
            Button("확인") {
                // 성공이면 로그인 화면으로 자동 복귀
                if alertTitle == "완료" {
                    dismiss()
                }
            }
        } message: {
            Text(alertMessage)
        }
    }

    // MARK: - Logic

    private func requestReset() async {
        guard !userId.isEmpty else {
            alertTitle = "알림"
            alertMessage = "ID를 입력해주세요."
            showAlert = true
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            try await AuthAPI.shared.requestPasswordReset(userId: userId)
            alertTitle = "완료"
            alertMessage = "해당 계정의 이메일로 임시 비밀번호를 발송했습니다.\n메일함을 확인해주세요."
            showAlert = true
        } catch {
            alertTitle = "알림"
            alertMessage = error.localizedDescription.isEmpty
                ? "해당 ID를 찾을 수 없거나 요청을 처리하지 못했습니다.\n잠시 후 다시 시도해주세요."
                : error.localizedDescription
            showAlert = true
        }
    }
}
