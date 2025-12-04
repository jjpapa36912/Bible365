////
////  ReadingProgressStore.swift
////  Bible365
////
////  Created by 김동준 on 11/26/25.
////
//
//import Foundation
//final class ReadingProgressStore: ObservableObject {
//    static let shared = ReadingProgressStore()
//    
//    @Published private(set) var profile: ReadingProfile = ReadingProfile()
//    
//    private let storageKeyBase = "reading_profile_v1"
//    
//    private init() {
//        load()
//    }
//    
//    // MARK: - 유저별 프로필 키 (로그인 시스템 있을 경우 userId 붙여서 사용)
//    private var storageKey: String {
//        // TODO: 로그인 시스템이 있다면 현재 유저 ID를 붙여서 구분
//        // 예: "\(storageKeyBase)_\(AuthManager.shared.currentUserId)"
//        return storageKeyBase
//    }
//    
//    // MARK: - 로드 / 세이브
//    
//    private func load() {
//        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
//        do {
//            let decoded = try JSONDecoder().decode(ReadingProfile.self, from: data)
//            self.profile = decoded
//        } catch {
//            print("⚠️ ReadingProgressStore load error: \(error)")
//        }
//    }
//    
//    private func save() {
//        do {
//            let data = try JSONEncoder().encode(profile)
//            UserDefaults.standard.set(data, forKey: storageKey)
//        } catch {
//            print("⚠️ ReadingProgressStore save error: \(error)")
//        }
//    }
//    
//    // MARK: - Verse 진행 업데이트
//    
//    /// 한 절의 파란색 단어 인덱스가 변경될 때마다 호출
//    func updateVerseProgress(
//        verseId: String,
//        bookCode: String,
//        totalWords: Int,
//        highlightedIndexes: Set<Int>
//    ) {
//        var profile = self.profile
//        
//        let newIndexes = Array(highlightedIndexes).sorted()
//        let newReadCount = newIndexes.count
//        
//        // 이전 진행 정보
//        let old = profile.verseProgressById[verseId]
//        let oldReadCount = old?.readWordCount ?? 0
//        
//        // verseProgress 갱신
//        let vp = VerseProgress(
//            verseId: verseId,
//            bookCode: bookCode,
//            totalWords: totalWords,
//            highlightedWordIndexes: newIndexes
//        )
//        profile.verseProgressById[verseId] = vp
//        
//        // 책 요약 갱신
//        var bookSummary = profile.bookProgressByCode[bookCode] ?? BookProgressSummary(
//            bookCode: bookCode,
//            readWordCount: 0,
//            totalWordCount: 0,
//            completionCount: 0
//        )
//        
//        // 이 절이 새로 등장하면 totalWordCount에 이 절 단어 수를 추가
//        if old == nil {
//            bookSummary.totalWordCount += totalWords
//        }
//        
//        // readWordCount 조정 (delta)
//        let delta = newReadCount - oldReadCount
//        bookSummary.readWordCount += delta
//        if bookSummary.readWordCount < 0 { bookSummary.readWordCount = 0 }
//        
//        // 책 완독 체크 (단순히 99% 이상이면 완독으로 간주)
//        if bookSummary.totalWordCount > 0 {
//            let ratio = Double(bookSummary.readWordCount) / Double(bookSummary.totalWordCount)
//            if ratio >= 0.99 {
//                // 완독 횟수 1 이상이어도 또 읽으면 증가시킬 건지?
//                // 일단 "처음 완독"만 카운트한다고 가정하지 않고,
//                // 완독 상태에 도달할 때마다 1 증가시킴.
//                bookSummary.completionCount += 1
//            }
//        }
//        
//        profile.bookProgressByCode[bookCode] = bookSummary
//        
//        // 전체 요약(Global) 갱신
//        var global = profile.global
//        
//        if old == nil {
//            global.totalWordCount += totalWords
//        }
//        global.readWordCount += delta
//        if global.readWordCount < 0 { global.readWordCount = 0 }
//        
//        // 전체 성경 완독 체크
//        if global.totalWordCount > 0 {
//            let ratio = Double(global.readWordCount) / Double(global.totalWordCount)
//            if ratio >= 0.99 {
//                global.completionCount += 1
//            }
//        }
//        
//        profile.global = global
//        
//        // 최종 반영
//        self.profile = profile
//        save()
//    }
//    
//    // MARK: - 조회 메서드
//    
//    /// 특정 절에 대한 저장된 파란색 단어 인덱스 (없으면 빈 집합)
//    func highlightedIndexes(for verseId: String) -> Set<Int> {
//        guard let vp = profile.verseProgressById[verseId] else { return [] }
//        return Set(vp.highlightedWordIndexes)
//    }
//    
//    /// 특정 책(예: "MAT") 기준 진행률 (0.0 ~ 1.0)
//    func progressForBook(bookCode: String) -> Double {
//        guard let b = profile.bookProgressByCode[bookCode], b.totalWordCount > 0 else {
//            return 0.0
//        }
//        return Double(b.readWordCount) / Double(b.totalWordCount)
//    }
//    
//    /// 전체 성경 기준 진행률 (0.0 ~ 1.0)
//    func globalProgress() -> Double {
//        let g = profile.global
//        guard g.totalWordCount > 0 else { return 0.0 }
//        return Double(g.readWordCount) / Double(g.totalWordCount)
//    }
//    
//    /// 특정 책 완독 횟수
//    func completionCountForBook(bookCode: String) -> Int {
//        profile.bookProgressByCode[bookCode]?.completionCount ?? 0
//    }
//    
//    /// 전체 성경 완독 횟수
//    func globalCompletionCount() -> Int {
//        profile.global.completionCount
//    }
//}
