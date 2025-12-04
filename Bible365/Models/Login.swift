//
//  Login.swift
//  Bible365
//
//  Created by 김동준 on 11/22/25.
//

import Foundation
struct LoginResponseDTO: Decodable {
    let accessToken: String
    let refreshToken: String
    let userId: Int64
    let nickname: String
}

struct LoginResponse: Codable {
    let accessToken: String
    let refreshToken: String
    let userId: Int   // ⬅️ 서버에서 숫자로 오니까 Int
    let nickname: String
}


final class AuthManager: ObservableObject {
    static let shared = AuthManager()

    @Published var token: String?     // JWT
    @Published var userId: Int64?     // (있으면 같이 저장)
    @Published var nickname: String?

    private init() {}

    func applyLogin(response: LoginResponse) {
        self.token = response.accessToken
        // self.userId = response.userId
        // self.nickname = response.nickname

        // 필요하면 UserDefaults, Keychain 등에 영구 저장
        UserDefaults.standard.set(response.accessToken, forKey: "jwtToken")
    }

    func restoreFromStorage() {
        if let saved = UserDefaults.standard.string(forKey: "jwtToken") {
            self.token = saved
        }
    }

    func logout() {
        token = nil
        userId = nil
        nickname = nil
        UserDefaults.standard.removeObject(forKey: "jwtToken")
    }
}

