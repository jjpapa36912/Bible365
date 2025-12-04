//
//  RankingViewModel.swift
//  Bible365
//
//  Created by 김동준 on 12/4/25.
//

import Foundation
// 랭킹 1줄


// 서버 전체 응답
struct RankingResponse: Codable {
    let currentUserId: Int64?
    let entries: [RankingEntry]
}

final class RankingViewModel: ObservableObject {

    @Published var entries: [RankingEntry] = []
    @Published var currentUserId: Int64? = nil
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    // TODO: 서버 주소에 맞게 수정
    private let baseURL: URL = {
        #if DEBUG
        return URL(string: "http://127.0.0.1:8080")! // 로컬 스프링부트
        #else
        return URL(string: "http://13.124.208.108:8080")! // 배포 서버
        #endif
    }()
    @MainActor
        func load() async {
            isLoading = true
            errorMessage = nil
            defer { isLoading = false }

            do {
                let url = baseURL.appendingPathComponent("/api/ranking")
                print("🔥 [RankingVM] request =", url.absoluteString)

                let (data, response) = try await URLSession.shared.data(from: url)

                if let http = response as? HTTPURLResponse {
                    print("🔥 [RankingVM] status =", http.statusCode)
                }
                if let raw = String(data: data, encoding: .utf8) {
                    print("🔥 [RankingVM] raw =", raw)
                }

                guard let http = response as? HTTPURLResponse,
                      (200..<300).contains(http.statusCode) else {
                    throw URLError(.badServerResponse)
                }

                let decoded = try JSONDecoder().decode(RankingResponse.self, from: data)
                print("🔥 [RankingVM] decoded entries =", decoded.entries.count,
                      " currentUserId =", String(describing: decoded.currentUserId))

                self.entries = decoded.entries
                self.currentUserId = decoded.currentUserId
            } catch {
                print("🚨 Ranking load error:", error)
                errorMessage = "랭킹 정보를 불러오지 못했습니다."
                self.entries = []         // 혹시 남아있을 예전 값 제거
            }
        }

}
