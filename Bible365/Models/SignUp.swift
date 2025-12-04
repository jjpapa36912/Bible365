//
//  SignUp.swift
//  Bible365
//
//  Created by 김동준 on 11/22/25.
//

import Foundation

struct SignupRequestDTO: Encodable {
    let userId: String
    let password: String
    let nickname: String
    let email: String
}

struct SignupResponseDTO: Decodable {
    let success: Bool
    let message: String
}

struct ResetPasswordResponseDTO: Decodable {
    let success: Bool
    let message: String
}

struct TokenRefreshRequestDTO: Encodable {
    let refreshToken: String
}

struct TokenRefreshResponseDTO: Decodable {
    let accessToken: String
    let refreshToken: String
}

