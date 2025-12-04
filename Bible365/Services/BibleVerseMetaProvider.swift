//
//  BibleVerseMetaProvider.swift
//  Bible365
//
//  Created by 김동준 on 11/26/25.
//

import Foundation
import SwiftUI

// MARK: - JSON 메타용 구조체 (네가 준 형식 그대로)

struct BibleMetaEntry: Decodable {
    let version: String   // "KOR096"
    let bookId: String    // "GEN"
    let chapter: Int
    let verse: Int
    let text: String
}

// MARK: - 66권 전체 / 각 책 절수 메타

@MainActor
final class BibleVerseMetaProvider {
    static let shared = BibleVerseMetaProvider()

    /// 각 책의 전체 절 수 (예: ["GEN": 1533, "EXO": ...])
    private(set) var bookTotalVerses: [String: Int] = [:]

    /// 성경 전체 절 수 (66권 합산)
    private(set) var globalTotalVerses: Int = 0

    private init() {
        loadFromJSON()
    }

    /// 번들에 포함된 JSON 파일에서 절수 계산
    private func loadFromJSON() {
        // 👉 여기 파일 이름/확장자만 네가 실제 추가한 이름으로 맞춰주면 됨
        guard let url = Bundle.main.url(forResource: "web", withExtension: "json") else {
            print("⚠️ BibleVerseMetaProvider: KOR096_all_verses.json not found in bundle")
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let entries = try JSONDecoder().decode([BibleMetaEntry].self, from: data)

            globalTotalVerses = entries.count

            var counts: [String: Int] = [:]
            for e in entries {
                counts[e.bookId, default: 0] += 1
            }
            self.bookTotalVerses = counts

            print("✅ BibleVerseMetaProvider loaded. globalTotalVerses=\(globalTotalVerses)")
        } catch {
            print("❌ BibleVerseMetaProvider load error: \(error)")
        }
    }

    /// 해당 책의 전체 절 수 (없으면 nil)
    func totalVerses(for bookCode: String) -> Int? {
        bookTotalVerses[bookCode]
    }
}
