//
//  BibleAPI.swift
//  Bible365
//
//  Created by 김동준 on 11/24/25.
//

import Foundation

// MARK: - 서버 DTO

/// 책 목록 DTO
struct BibleBookDTO: Identifiable, Decodable {
    let code: String      // 예: "GEN"
    let name: String      // 예: "창세기"
    let chapters: Int     // 전체 장 수

    var id: String { code }
}

struct BibleVerseDTO: Decodable {
    let version: String
    let bookCode: String
    let chapter: Int
    let verse: Int
    let text: String

    enum CodingKeys: String, CodingKey {
        case version
        case bookCode = "bookId"   // 서버의 bookId → bookCode로 매핑
        case chapter
        case verse
        case text
    }
}



// MARK: - 실제 API 클라이언트

final class BibleAPI {
    static let shared = BibleAPI()
    private init() {}

    /// 👉 여기 네 스프링부트 서버 주소로 변경
    private let baseURL: URL = {
        #if DEBUG
        return URL(string: "http://127.0.0.1:8080")! // 로컬 스프링부트
        #else
        return URL(string: "http://13.124.208.108:8080")! // 배포 서버
        #endif
    }()
    
    private let baseURLString: String = {
        #if DEBUG
        return "http://127.0.0.1:8080"   // 로컬 스프링부트
        #else
        return "http://13.124.208.108:8080" // 배포 서버
        #endif
    }()


    // MARK: - 공통 로그 헬퍼

    private func log(_ message: String) {
        print("📖 [BibleAPI]", message)
    }

    // MARK: - 책 목록 불러오기

    /// 전체 성경 책 목록
    ///
    /// 예: GET /api/bible/books
    func fetchBooks() async throws -> [BibleBookDTO] {
        let url = baseURL.appendingPathComponent("/api/bible/books")
        log("➡️ fetchBooks() request: \(url.absoluteString)")

        let (data, response) = try await URLSession.shared.data(from: url)

        if let http = response as? HTTPURLResponse {
            log("⬅️ fetchBooks() status: \(http.statusCode)")
        }

        log("⬅️ fetchBooks() raw bytes: \(data.count)")

        if let raw = String(data: data, encoding: .utf8) {
            // 너무 길면 앞부분만 잘라서 출력
            let preview = raw.count > 500 ? String(raw.prefix(500)) + " ..." : raw
            log("⬅️ fetchBooks() raw body: \(preview)")
        } else {
            log("⚠️ fetchBooks() body is not valid UTF-8 string")
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        do {
            let result = try decoder.decode([BibleBookDTO].self, from: data)
            log("✅ fetchBooks() decoded count: \(result.count)")
            return result
        } catch {
            log("❌ fetchBooks() decode error: \(error)")
            throw error
        }
    }

    // MARK: - 특정 구절 불러오기

    /// 특정 책/장/절 본문 + maxChapter/maxVerse
    ///
    /// 예: GET /api/bible/verse?bookCode=GEN&chapter=1&verse=1
    func fetchVerse(bookCode: String, chapter: Int, verse: Int) async throws -> BibleVerseDTO {

        var comp = URLComponents(
            url: baseURL.appendingPathComponent("/api/bible/verse"),
            resolvingAgainstBaseURL: false
        )!

        comp.queryItems = [
            URLQueryItem(name: "bookCode", value: bookCode),
            URLQueryItem(name: "chapter", value: String(chapter)),
            URLQueryItem(name: "verse", value: String(verse))
        ]

        guard let url = comp.url else {
            log("❌ fetchVerse() failed to build URL from components: \(comp)")
            throw URLError(.badURL)
        }

        log("➡️ fetchVerse() request: \(url.absoluteString)")

        let (data, response) = try await URLSession.shared.data(from: url)

        if let http = response as? HTTPURLResponse {
            log("⬅️ fetchVerse() status: \(http.statusCode)")
        }

        log("⬅️ fetchVerse() raw bytes: \(data.count)")

        if let raw = String(data: data, encoding: .utf8) {
            let preview = raw.count > 500 ? String(raw.prefix(500)) + " ..." : raw
            log("⬅️ fetchVerse() raw body: \(preview)")
        } else {
            log("⚠️ fetchVerse() body is not valid UTF-8 string")
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        do {
            let result = try decoder.decode(BibleVerseDTO.self, from: data)
            log("✅ fetchVerse() decoded: \(result.bookCode) \(result.chapter):\(result.verse)")
            return result
        } catch {
            log("❌ fetchVerse() decode error: \(error)")
            throw error
        }
    }
    
    


}
// BibleAPI.swift

extension BibleAPI {
    func addAuthHeader(_ request: inout URLRequest) {
            guard var token = UserDefaults.standard.string(forKey: "jwtToken") else {
                print("⚠️ addAuthHeader: jwtToken 없음")
                return
            }

            // 이미 "Bearer "로 시작하면 그대로 사용
            if !token.lowercased().hasPrefix("bearer ") {
                token = "Bearer \(token)"
            }

            print("🔐 Authorization 헤더 세팅: \(token)") // 디버깅용
            request.addValue(token, forHTTPHeaderField: "Authorization")
        }

    struct LastReadPositionRequestDTO: Codable {
        let verseId: String
        let mode: String
        let teamId: Int?
        let teamName: String?
    }

    struct LastReadPositionResponseDTO: Codable {
        let verseId: String
        let mode: String
        let teamId: Int?
        let teamName: String?
    }


    /// 저장된 이어읽기 위치 조회 (없으면 nil)
    // 이어읽기 위치 조회
    // BibleAPI.swift

    func fetchLastReadPosition() async throws -> LastReadPositionResponseDTO? {
        guard let url = URL(string: "\(baseURL)/api/reading/last-read") else { return nil }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // 토큰 헤더 추가
        if let token = UserDefaults.standard.string(forKey: "accessToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else { return nil }

        // 🚨 [핵심 수정] 401 (토큰 만료) 감지 시 강제 로그아웃 신호 발송
        if httpResponse.statusCode == 401 {
            print("❌ 토큰 만료됨 (401) -> 로그인 화면으로 이동합니다.")
            
            // 메인 스레드에서 알림 발송
            await MainActor.run {
                NotificationCenter.default.post(name: .forceLogout, object: nil)
            }
            
            throw APIError.unauthorized
        }
        
        // 404 처리 (기록 없음)
        if httpResponse.statusCode == 404 {
            return nil
        }
        
        // 200 OK 처리
        if (200...299).contains(httpResponse.statusCode) {
            return try JSONDecoder().decode(LastReadPositionResponseDTO.self, from: data)
        }
        
        return nil
    }
    /// 이어읽기 위치 갱신
    // ✅ 3. 마지막 읽은 위치 저장 (LastReadPosition)
        func updateLastReadPosition(verseId: String, mode: String, teamId: Int?, teamName: String?) async throws {
            
            struct LastReadBody: Codable {
                let verseId: String
                let mode: String
                let teamId: Int?
            }
            
            let body = LastReadBody(verseId: verseId, mode: mode, teamId: teamId)
            
            // URL 생성
            guard let url = URL(string: "\(baseURL)/api/reading/last-read") else { return }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            // ====================================================
            // ✅ [핵심 수정] 토큰이 있으면 헤더에 추가 (이게 없어서 401 뜸)
            // ====================================================
            if let token = UserDefaults.standard.string(forKey: "accessToken") {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            } else {
                print("❌ [LastRead] 저장 실패: 로컬에 토큰이 없습니다. (로그인 필요)")
                throw APIError.unauthorized
            }
            // ====================================================
            
            request.httpBody = try JSONEncoder().encode(body)
            
            let (_, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                // 401(만료)이면 강제 로그아웃 신호 보내기 (이전에 만든 로직 활용)
                if httpResponse.statusCode == 401 {
                    print("❌ [LastRead] 401 Unauthorized: 토큰 만료됨 -> 강제 로그아웃 처리")
                    
                    await MainActor.run {
                        NotificationCenter.default.post(name: .forceLogout, object: nil)
                    }
                    
                    throw APIError.unauthorized
                }
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    print("❌ [LastRead] 서버 에러: Status \(httpResponse.statusCode)")
                    throw URLError(.badServerResponse)
                }
                
                print("✅ 위치 저장 성공: \(verseId)")
            }
        }
}
enum APIError: Error {
    case network
    case unauthorized          // 🔹 401 전용
    case httpStatus(code: Int)
    case decoding
}
extension BibleAPI {

    struct TeamProgressUpdateRequestDTO: Codable {
        let completionCount: Int
        let progress: Double
    }

    struct TeamProgressEntryDTO: Codable {
        let userId: Int
        let nickname: String
        let completionCount: Int
        let progress: Double
    }

    // 🔹 팀 진행도 갱신
    func updateTeamProgress(teamId: Int,
                            completionCount: Int,
                            progress: Double) async throws {
        let url = baseURL.appendingPathComponent("/api/team/\(teamId)/progress")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        addAuthHeader(&request)

        let body = TeamProgressUpdateRequestDTO(
            completionCount: completionCount,
            progress: progress
        )
        request.httpBody = try JSONEncoder().encode(body)

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw APIError.network
        }

        if http.statusCode == 401 {
            throw APIError.unauthorized
        }
        guard (200...299).contains(http.statusCode) else {
            throw APIError.httpStatus(code: http.statusCode)
        }
    }

    // 🔹 팀 랭킹 보드 조회
    func fetchTeamRanking(teamId: Int) async throws -> [TeamProgressEntryDTO] {
        let url = baseURL.appendingPathComponent("/api/team/\(teamId)/progress/ranking")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        addAuthHeader(&request)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw APIError.network
        }

        if http.statusCode == 401 {
            throw APIError.unauthorized
        }
        guard (200...299).contains(http.statusCode) else {
            throw APIError.httpStatus(code: http.statusCode)
        }

        return try JSONDecoder().decode([TeamProgressEntryDTO].self, from: data)
    }

    // 🔹 내가 이 팀에서 어느 정도인지 조회
    func fetchMyTeamProgress(teamId: Int) async throws -> TeamProgressEntryDTO? {
        let url = baseURL.appendingPathComponent("/api/team/\(teamId)/progress/me")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        addAuthHeader(&request)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw APIError.network
        }

        if http.statusCode == 401 {
            throw APIError.unauthorized
        }
        if http.statusCode == 404 {
            return nil
        }
        guard (200...299).contains(http.statusCode) else {
            throw APIError.httpStatus(code: http.statusCode)
        }

        return try JSONDecoder().decode(TeamProgressEntryDTO.self, from: data)
    }
}
extension BibleAPI {
    struct PersonalProgressRequest: Encodable {
        let completionCount: Int
        let progress: Double
    }

    @MainActor
    func updatePersonalProgress(completionCount: Int, progress: Double) async throws {
        let url = baseURL.appendingPathComponent("/api/bible/personal/progress")

        let body = PersonalProgressRequest(
            completionCount: completionCount,
            progress: progress
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              200..<300 ~= httpResponse.statusCode else {
            throw URLError(.badServerResponse)
        }

        print("📡 personal progress updated OK")
    }
}

extension BibleAPI {
    
    // 서버로 보낼 DTO
    struct HighlightRequestDTO: Codable {
        let verseId: String
        let mode: String
        let teamId: Int?
        let indexes: [Int] // 파란색 칠해진 단어 순서들
    }
    
    struct HighlightResponseDTO: Decodable {
        let indexes: [Int]
    }
    
    // ✅ 1. 하이라이트 정보 저장 (절 이동 시 호출)
    func saveHighlights(verseId: String, mode: String, teamId: Int?, indexes: [Int]) async throws {
        guard let url = URL(string: "\(baseURLString)/api/progress/save") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 토큰 추가
        if let token = UserDefaults.standard.string(forKey: "accessToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let body = HighlightRequestDTO(verseId: verseId, mode: mode, teamId: teamId, indexes: indexes)
        request.httpBody = try JSONEncoder().encode(body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        if let http = response as? HTTPURLResponse, http.statusCode == 401 {
            // 토큰 만료 처리 등
            throw APIError.unauthorized
        }
    }
    
    // ✅ 2. 하이라이트 정보 불러오기 (절 진입 시 호출)
    func fetchHighlights(verseId: String, mode: String, teamId: Int?) async throws -> [Int] {
        var urlString = "\(baseURLString)/api/progress/\(verseId)?mode=\(mode)"
        if let tid = teamId {
            urlString += "&teamId=\(tid)"
        }
        
        guard let url = URL(string: urlString) else { return [] }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        if let token = UserDefaults.standard.string(forKey: "accessToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let http = response as? HTTPURLResponse {
            if http.statusCode == 401 { throw APIError.unauthorized }
            if http.statusCode != 200 { return [] } // 데이터 없으면 빈 배열
        }
        
        // Response: { "indexes": [0, 1, 5] }
        let decoded = try JSONDecoder().decode(HighlightResponseDTO.self, from: data)
        return decoded.indexes
    }
}
