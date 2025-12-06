import SwiftUI

struct RootView: View {
    @State private var isLoggedIn = false
    @State private var showSignup = false
    @State private var showFindPassword = false

    var body: some View {
        NavigationStack {
            Group {
                if isLoggedIn {
                    // 🔹 메인 화면
                    MainScreenView(
                        onLogout: {
                            logout()
                        }
                    )
                } else {
                    // 🔹 로그인 화면
                    LoginView(
                        onLoginSuccess: {
                                // ✅ 1) (LoginView 내부에서) userId, nickname을 UserDefaults에 먼저 저장했다고 가정
                                // UserDefaults.standard.set(userId, forKey: "userId")
                                // UserDefaults.standard.set(nickname, forKey: "nickname")

                                // ✅ 2) 현재 userId 기준으로 ReadingProgressStore를 다시 로드
                                ReadingProgressStore.shared.reloadForCurrentUser()

                                // ✅ 3) 메인 화면으로 전환
                                self.isLoggedIn = true
                            },
                        onSignupTapped: {
                            showSignup = true
                        },
                        onFindPasswordTapped: {
                            showFindPassword = true
                        }
                    )
                }
            }
            .onAppear {
                checkAutoLogin()
            }
            // 🔹 회원가입 화면으로 네비게이션
            .navigationDestination(isPresented: $showSignup) {
                SignupView()
            }
            // 🔹 비밀번호 찾기 화면으로 네비게이션
            .navigationDestination(isPresented: $showFindPassword) {
                FindPasswordView()
            }
            // 🚨 [핵심 수정] 강제 로그아웃 신호 감지
                    .onReceive(NotificationCenter.default.publisher(for: .forceLogout)) { _ in
                        print("🔄 강제 로그아웃 실행 (세션 만료)")
                        
                        // 1. 토큰 삭제
                        UserDefaults.standard.removeObject(forKey: "accessToken")
                        UserDefaults.standard.removeObject(forKey: "refreshToken")
                        UserDefaults.standard.removeObject(forKey: "userId")
                        
                        // 2. 로그인 상태 해제 -> 로그인 화면으로 전환됨
                        isLoggedIn = false
                    }
        }
    }

    /// 자동 로그인 체크 (Keychain 에 토큰 있으면 바로 메인으로)
    func checkAutoLogin() {
        if let token = KeychainManager.get(key: "accessToken"),
           !token.isEmpty {
            isLoggedIn = true
        }
    }
    
    /// 로그아웃 처리: 토큰/유저정보 제거 + 로그인 화면으로 전환
    func logout() {
        // Keychain 토큰 삭제
        KeychainManager.delete(key: "accessToken")
        KeychainManager.delete(key: "refreshToken")

        // UserDefaults 정리
        UserDefaults.standard.removeObject(forKey: "userId")
        UserDefaults.standard.removeObject(forKey: "nickname")

        // 🔹 로그인 화면으로 이동
        isLoggedIn = false

        // 옵션: 회원가입/비번찾기 플래그도 초기화
        showSignup = false
        showFindPassword = false
    }
}
