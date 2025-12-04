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
