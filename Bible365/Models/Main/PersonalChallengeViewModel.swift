import Foundation

// MARK: - 한 절 단위 모델 (한국어만 사용)

// MARK: - 진행도 모델들 (절 / 책 / 전체)
/// 이어읽기용 - 서버/로컬에서 가져온 "마지막 읽은 구절" 정보

// =======================
// 진행도 모델 (그대로 사용)
// =======================


// =======================
// 진행도 모델 (기존 그대로)
// =======================

struct LastReadVerse {
    let bookCode: String
    let bookName: String
    let chapter: Int
    let verse: Int
}

struct VerseProgress: Codable {
    let verseId: String
    let bookCode: String
    var highlightedWordIndexes: [Int]
    var isCompleted: Bool
}

struct BookProgressSummary: Codable {
    let bookCode: String
    var completedVerseCount: Int
    var totalVerseCount: Int
    var completionCount: Int
}

struct GlobalProgressSummary: Codable {
    var completedVerseCount: Int
    var totalVerseCount: Int
    var completionCount: Int
}

struct ReadingProfile: Codable {
    var verseProgressById: [String: VerseProgress] = [:]
    var bookProgressByCode: [String: BookProgressSummary] = [:]
    var global: GlobalProgressSummary = .init(
        completedVerseCount: 0,
        totalVerseCount: 0,
        completionCount: 0
    )
}

// =======================
// 진행도 저장소 (모드 + 팀별 분리 버전)
// =======================

@MainActor
final class ReadingProgressStore: ObservableObject {
    static let shared = ReadingProgressStore()

    /// 🔹 personal 모드 프로필은 여전히 바로 접근 가능하게 노출 (홈 보드용)
    @Published private(set) var profile: ReadingProfile = ReadingProfile()

    /// 🔹 모드+팀별 프로필 저장소
    ///
    /// key 예시:
    ///  - "personal"
    ///  - "team_1", "team_2", ...
    private var profilesByModeKey: [String: ReadingProfile] = [:]

    private let storageKeyBase = "reading_profile_v4_verseBased_byMode"  // 🔸 v4로 버전업
    private let meta = BibleVerseMetaProvider.shared

    private init() {
        load()
        applyMetaToAllProfiles()
    }

    // MARK: - 모드 → 내부 키

    private func modeKey(for mode: BibleProgressMode) -> String {
        switch mode {
        case .personal:
            return "personal"
        case .team(let teamId, _):
            return "team_\(teamId)"
        }
    }


    /// 해당 모드의 프로필을 가져오거나 새로 생성
    private func ensureProfile(for mode: BibleProgressMode) -> ReadingProfile {
        let key = modeKey(for: mode)

        if let existing = profilesByModeKey[key] {
            return existing
        }

        var newProfile = ReadingProfile()
        let total = meta.globalTotalVerses
        if total > 0 {
            newProfile.global.totalVerseCount = total
        }

        profilesByModeKey[key] = newProfile

        if key == "personal" {
            self.profile = newProfile
        }
        return newProfile
    }

    // MARK: - UserDefaults 키

    private var storageKey: String {
        if let id = UserDefaults.standard.object(forKey: "userId") as? Int {
            return "\(storageKeyBase)_user_\(id)"
        } else {
            return storageKeyBase
        }
    }

    func reloadForCurrentUser() {
        profilesByModeKey.removeAll()
        self.profile = ReadingProfile()
        load()
        applyMetaToAllProfiles()
    }

    // MARK: - 로드/세이브

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        let decoder = JSONDecoder()
        do {
            // 1) v4 형식: [String: ReadingProfile]
            if let dict = try? decoder.decode([String: ReadingProfile].self, from: data) {
                self.profilesByModeKey = dict
                self.profile = dict["personal"] ?? ReadingProfile()
                return
            }

            // 2) v3 형식: 단일 ReadingProfile → personal로 이관
            let single = try decoder.decode(ReadingProfile.self, from: data)
            self.profilesByModeKey = ["personal": single]
            self.profile = single
            save()
        } catch {
            print("⚠️ ReadingProgressStore load error: \(error)")
        }
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(profilesByModeKey)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("⚠️ ReadingProgressStore save error: \(error)")
        }
    }

    /// 메타의 전체 절 수를 모든 프로필에 반영
    private func applyMetaToAllProfiles() {
        let total = meta.globalTotalVerses
        guard total > 0 else { return }

        for (key, var p) in profilesByModeKey {
            p.global.totalVerseCount = total
            profilesByModeKey[key] = p
            if key == "personal" {
                self.profile = p
            }
        }

        // 아무것도 없으면 personal 하나는 만들어 둠
        if profilesByModeKey["personal"] == nil {
            var p = ReadingProfile()
            p.global.totalVerseCount = total
            profilesByModeKey["personal"] = p
            self.profile = p
        }
    }

    // MARK: - 디버그: 특정 모드용

    func debugFillAllAsReadExceptMark11(mode: BibleProgressMode) {
        let key = modeKey(for: mode)
        let oldProfile = ensureProfile(for: mode)
        var newProfile = ReadingProfile()

        let allBookCodes: [String] = [
            "GEN","EXO","LEV","NUM","DEU","JOS","JDG","RUT",
            "1SA","2SA","1KI","2KI","1CH","2CH","EZR","NEH","EST",
            "1CO","2CO","GAL","EPH","PHP","COL",
            "1TH","2TH","1TI","2TI","TIT","PHM",
            "HEB","JAS","1PE","2PE","1JN","2JN","3JN","JUD","REV"
        ]

        var totalVerses = 0
        var totalCompleted = 0

        for code in allBookCodes {
            let metaTotal = meta.totalVerses(for: code)
            let total = (metaTotal ?? 0) > 0 ? metaTotal! : 1

            if metaTotal == nil || metaTotal == 0 {
                print("⚠️ debugFillAllAsReadExceptMark11: meta 없음/0 → \(code)은 임시 total=1로 처리")
            }

            var completed = total
            if code == "MRK" {
                completed = max(0, total - 1)
            }

            totalVerses += total
            totalCompleted += completed

            let oldBookCompletion = oldProfile.bookProgressByCode[code]?.completionCount ?? 0

            let summary = BookProgressSummary(
                bookCode: code,
                completedVerseCount: completed,
                totalVerseCount: total,
                completionCount: oldBookCompletion
            )
            newProfile.bookProgressByCode[code] = summary
        }

        newProfile.global.totalVerseCount = totalVerses
        newProfile.global.completedVerseCount = totalCompleted
        newProfile.global.completionCount = oldProfile.global.completionCount

        profilesByModeKey[key] = newProfile
        if key == "personal" {
            self.profile = newProfile
        }
        save()
    }

    // MARK: - 업데이트 (모드별)

    func updateVerseProgress(
        mode: BibleProgressMode,
        verseId: String,
        bookCode: String,
        highlightedIndexes: Set<Int>,
        isCompleted: Bool
    ) {
        let key = modeKey(for: mode)
        var profile = ensureProfile(for: mode)

        let newIndexes = Array(highlightedIndexes).sorted()
        let old = profile.verseProgressById[verseId]
        let wasCompleted = old?.isCompleted ?? false

        let vp = VerseProgress(
            verseId: verseId,
            bookCode: bookCode,
            highlightedWordIndexes: newIndexes,
            isCompleted: isCompleted
        )
        profile.verseProgressById[verseId] = vp

        let deltaCompleted = (isCompleted ? 1 : 0) - (wasCompleted ? 1 : 0)

        // --- 책 요약 ---
        var bookSummary = profile.bookProgressByCode[bookCode] ?? BookProgressSummary(
            bookCode: bookCode,
            completedVerseCount: 0,
            totalVerseCount: meta.totalVerses(for: bookCode) ?? 0,
            completionCount: 0
        )

        if let total = meta.totalVerses(for: bookCode), total > 0 {
            bookSummary.totalVerseCount = total
        }

        bookSummary.completedVerseCount += deltaCompleted
        if bookSummary.completedVerseCount < 0 { bookSummary.completedVerseCount = 0 }

        if bookSummary.totalVerseCount > 0,
           deltaCompleted > 0,
           bookSummary.completedVerseCount == bookSummary.totalVerseCount {
            bookSummary.completionCount += 1
        }

        profile.bookProgressByCode[bookCode] = bookSummary

        // --- 전체(global) ---
        var global = profile.global
        let globalTotal = meta.globalTotalVerses
        if globalTotal > 0 {
            global.totalVerseCount = globalTotal
        }

        global.completedVerseCount += deltaCompleted
        if global.completedVerseCount < 0 { global.completedVerseCount = 0 }

        if global.totalVerseCount > 0,
           deltaCompleted > 0,
           global.completedVerseCount == global.totalVerseCount {
            global.completionCount += 1
        }

        profile.global = global

        profilesByModeKey[key] = profile
        if key == "personal" {
            self.profile = profile
        }
        save()
    }

    // MARK: - 조회 (모드별)

    func highlightedIndexes(for verseId: String, mode: BibleProgressMode) -> Set<Int> {
        let profile = ensureProfile(for: mode)
        guard let vp = profile.verseProgressById[verseId] else { return [] }
        return Set(vp.highlightedWordIndexes)
    }

    func progressForBook(bookCode: String, mode: BibleProgressMode) -> Double {
        let profile = ensureProfile(for: mode)
        guard let total = meta.totalVerses(for: bookCode), total > 0 else {
            return 0.0
        }
        let completed = profile.bookProgressByCode[bookCode]?.completedVerseCount ?? 0
        return Double(completed) / Double(total)
    }

    func globalProgress(mode: BibleProgressMode) -> Double {
        let profile = ensureProfile(for: mode)
        let total = meta.globalTotalVerses
        guard total > 0 else { return 0.0 }
        let completed = profile.global.completedVerseCount
        return Double(completed) / Double(total)
    }

    func completionCountForBook(bookCode: String, mode: BibleProgressMode) -> Int {
        let profile = ensureProfile(for: mode)
        return profile.bookProgressByCode[bookCode]?.completionCount ?? 0
    }

    func globalCompletionCount(mode: BibleProgressMode) -> Int {
        let profile = ensureProfile(for: mode)
        return profile.global.completionCount
    }

    // MARK: - 전체 리셋 (모드별)

    func resetAllProgress(keepCompletionCounts: Bool, mode: BibleProgressMode) {
        let key = modeKey(for: mode)
        var profile = ensureProfile(for: mode)

        profile.verseProgressById.removeAll()

        profile.bookProgressByCode = profile.bookProgressByCode.mapValues { summary in
            var s = summary
            s.completedVerseCount = 0
            if !keepCompletionCounts {
                s.completionCount = 0
            }
            return s
        }

        var global = profile.global
        global.completedVerseCount = 0
        if !keepCompletionCounts {
            global.completionCount = 0
        }
        profile.global = global

        profilesByModeKey[key] = profile
        if key == "personal" {
            self.profile = profile
        }

        save()
    }
}









extension PersonalChallengeViewModel {
    /// verseId ("2SA-1-1" 등)로 현재 verses 배열에서 찾기
       func findVerseById(_ verseId: String) -> BibleVerse? {
           return verses.first { $0.id == verseId }
       }
    @MainActor
    func loadFromVerseId(_ verseId: String) async {
        // TODO: verseId → BibleVerse 로 찾는 로직
        // ex) local JSON, DB, 서버 호출 등
        if let verse = findVerseById(verseId) {
            self.currentVerse = verse
            // 필요하면 totalProgress도 갱신
        }
    }
}

// MARK: - 뷰 모델 관련 타입들

struct BibleVerse: Identifiable, Equatable {
    let id: String      // 예: "GEN-1-1"
    let book: String    // 책 이름 (한글 표시용)
    let chapter: Int
    let verse: Int
      // "2SA"

    let text: String    // 한국어 본문
}

struct SttResponse: Decodable {
    let text: String
}

enum PersonalChallengeStep {
    case selectCategory
    case selectVerse
    case reading
}

enum BibleCategory: String, CaseIterable, Identifiable {
    case whole = "성경 전체"
    case oldTestament = "구약"
    case newTestament = "신약"
    case gospels = "복음서"
    case psalmsProverbs = "시편·잠언"
    case custom = "직접 선택"

    var id: String { rawValue }

    var subtitle: String {
        switch self {
        case .whole:          return "창세기부터 요한계시록까지"
        case .oldTestament:   return "창세기 ~ 말라기"
        case .newTestament:   return "마태복음 ~ 요한계시록"
        case .gospels:        return "마태·마가·누가·요한복음"
        case .psalmsProverbs: return "위로와 지혜의 말씀"
        case .custom:         return "내가 직접 책·장·절을 고를게요"
        }
    }
}

// MARK: - ViewModel



@MainActor
final class PersonalChallengeViewModel: ObservableObject {

    // MARK: - Published 상태
    @Published var isListening: Bool = false

    @Published var mode: BibleProgressMode

    @Published var currentVerse: BibleVerse
    @Published var highlightedWordIndexes: Set<Int> = []

    @Published var selectedCategory: BibleCategory? = nil
    @Published var books: [BibleBookDTO] = []
    @Published var filteredBooks: [BibleBookDTO] = []
    @Published var selectedBookCode: String? = nil

    @Published var totalProgress: Double = 0.0
    @Published var globalProgressValue: Double = 0.0
    @Published var didFinishWholeBibleRound: Bool = false

    @Published var maxChapter: Int = 150
    @Published var maxVerse: Int = 176

    private var verses: [BibleVerse] = []

    private let progressStore = ReadingProgressStore.shared
    private let completionThreshold: Double = 0.9
    private var lastKnownGlobalCompletionCount: Int

    init(mode: BibleProgressMode = .personal) {
        self.mode = mode
        self.currentVerse = BibleVerse(
            id: "INIT-1-1",
            book: "",
            chapter: 1,
            verse: 1,
            text: ""
        )

        self.lastKnownGlobalCompletionCount = progressStore.globalCompletionCount(mode: mode)
        self.globalProgressValue = progressStore.globalProgress(mode: mode)
    }

    // MARK: - verseId → bookCode
    private func saveLastReadPosition() {
           guard !currentVerse.id.isEmpty else { return }
           
           let vId = currentVerse.id
           // 🔹 헬퍼 함수를 통해 현재 모드에 맞는 (modeString, teamId)를 가져옴
           let (modeStr, teamId) = getModeParams()

           Task {
               try? await BibleAPI.shared.updateLastReadPosition(
                   verseId: vId,
                   mode: modeStr,
                   teamId: teamId, // 🚀 여기가 핵심: 팀이면 ID가 가고, 개인이면 nil이 감
                   teamName: nil
               )
           }
       }

       // 헬퍼 함수
       private func getModeParams() -> (String, Int?) {
           switch self.mode {
           case .personal:
               return ("personal", nil) // 🚀 개인은 무조건 nil
           case .team(let id, _):
               return ("team", id)      // 🚀 팀은 무조건 해당 ID
           }
       }
    private func bookCode(from verseId: String) -> String {
        verseId.split(separator: "-").first.map(String.init) ?? ""
    }

    // MARK: - 절 완료 처리

    func handleVerseCompleted(_ verse: BibleVerse) {
        let code = bookCode(from: verse.id)
        progressStore.updateVerseProgress(
            mode: mode,
            verseId: verse.id,
            bookCode: code,
            highlightedIndexes: highlightedWordIndexes,
            isCompleted: true
        )
        recalcBookAndGlobalProgress()
        checkAndResetIfFinishedWholeBible()
    }

    // MARK: - 진행도 + 스토어 연동

    private func recalcAndPersistProgress() {
        let verseId = currentVerse.id
        let code = bookCode(from: verseId)
        let isCompleted = isCurrentVerseCompleted()

        progressStore.updateVerseProgress(
            mode: mode,
            verseId: verseId,
            bookCode: code,
            highlightedIndexes: highlightedWordIndexes,
            isCompleted: isCompleted
        )

        recalcBookAndGlobalProgress()
        checkAndResetIfFinishedWholeBible()
    }

    private func recalcBookAndGlobalProgress() {
        let code = bookCode(from: currentVerse.id)
        totalProgress = progressStore.progressForBook(bookCode: code, mode: mode)
        globalProgressValue = progressStore.globalProgress(mode: mode)
    }

    private func loadHighlightForCurrentVerse() {
        let stored = progressStore.highlightedIndexes(for: currentVerse.id, mode: mode)
        highlightedWordIndexes = stored
    }

    private func checkAndResetIfFinishedWholeBible() {
        let currentCount = progressStore.globalCompletionCount(mode: mode)
        guard currentCount > lastKnownGlobalCompletionCount else { return }

        lastKnownGlobalCompletionCount = currentCount
        didFinishWholeBibleRound = true   // 뷰에서 Alert 띄우는 용도
    }

    func checkAndResetIfFinishedPersonal() {
        checkAndResetIfFinishedWholeBible()
    }

    func resetAllProgressForNewRound() {
        progressStore.resetAllProgress(keepCompletionCounts: true, mode: mode)

        highlightedWordIndexes.removeAll()
        totalProgress = 0.0
        globalProgressValue = progressStore.globalProgress(mode: mode)

        loadHighlightForCurrentVerse()
    }

    func forceResetAllProgressForNewRoundFromTeam() {
        resetAllProgressForNewRound()
    }

    func debugMarkAllAsReadExceptMark11() {
        let targetVerseId = "MRK-1-1"

        progressStore.debugFillAllAsReadExceptMark11(mode: mode)

        lastKnownGlobalCompletionCount = progressStore.globalCompletionCount(mode: mode)
        globalProgressValue = progressStore.globalProgress(mode: mode)
        totalProgress = progressStore.progressForBook(bookCode: "MRK", mode: mode)

        selectedBookCode = "MRK"
        currentVerse = BibleVerse(
            id: targetVerseId,
            book: localizedBookName(for: "MRK", fallback: "마가복음"),
            chapter: 1,
            verse: 1,
            text: currentVerse.text
        )
        highlightedWordIndexes.removeAll()

        Task {
            try? await loadCurrentVerseFromServer()
        }
    }

    func progressForBook(_ bookCode: String) -> Double {
        progressStore.progressForBook(bookCode: bookCode, mode: mode)
    }
    // MARK: - 이어읽기 / 특정 절로 점프

    /// "PRO-3-5" 이런 verseId 로 이동
    func jumpToVerse(verseId: String) async {
        // "PRO-3-5" → ["PRO","3","5"]
        let parts = verseId.split(separator: "-")
        guard parts.count == 3 else { return }

        let bookCode = String(parts[0])
        let chapter = Int(parts[1]) ?? 1
        let verse = Int(parts[2]) ?? 1

        // 1) 책 목록 로딩 보장
        await loadBooksIfNeeded()

        await MainActor.run {
            self.selectedBookCode = bookCode

            if let book = books.first(where: { $0.code == bookCode }) {
                self.currentVerse = BibleVerse(
                    id: verseId,
                    book: localizedBookName(for: book.code, fallback: book.name),
                    chapter: chapter,
                    verse: verse,
                    text: ""
                )
            } else {
                self.currentVerse = BibleVerse(
                    id: verseId,
                    book: localizedBookName(for: bookCode, fallback: bookCode),
                    chapter: chapter,
                    verse: verse,
                    text: ""
                )
            }
        }

        // 2) 실제 본문 API 호출
        try? await loadCurrentVerseFromServer()
    }

    // MARK: - 현재 절 단어/진행률

    /// 현재 절을 공백 기준으로 나눈 단어 배열
    var words: [String] {
        splitToWords(currentVerse.text)
    }

    /// 현재 절 진행률 (단어 기준)
    var verseProgress: Double {
        guard !words.isEmpty else { return 0 }
        return Double(highlightedWordIndexes.count) / Double(words.count)
    }

    /// 현재 절을 완료로 볼지 여부
    private func isCurrentVerseCompleted() -> Bool {
        guard !words.isEmpty else { return false }
        return verseProgress >= completionThreshold
    }

    /// verseId에서 bookCode 추출 (예: "PRO-1-1" -> "PRO")
    
    // MARK: - 책/장/절 변경

    func updateVerse(bookCode: String?, chapter: Int, verse: Int) {
        if let code = bookCode {
            selectedBookCode = code

            if let book = books.first(where: { $0.code == code }) {
                self.currentVerse = BibleVerse(
                    id: "\(code)-\(chapter)-\(verse)",
                    book: localizedBookName(for: book.code, fallback: book.name),
                    chapter: chapter,
                    verse: verse,
                    text: ""
                )
            } else {
                self.currentVerse = BibleVerse(
                    id: "\(code)-\(chapter)-\(verse)",
                    book: localizedBookName(for: code, fallback: code),
                    chapter: chapter,
                    verse: verse,
                    text: ""
                )
            }
        } else {
            self.currentVerse = BibleVerse(
                id: "\(selectedBookCode ?? "")-\(chapter)-\(verse)",
                book: currentVerse.book,
                chapter: chapter,
                verse: verse,
                text: currentVerse.text
            )
        }

        Task {
            try? await loadCurrentVerseFromServer()
        }
    }

    func goToNextVerse() {
        var nextChapter = currentVerse.chapter
        var nextVerse = currentVerse.verse + 1

        if nextVerse > maxVerse {
            if nextChapter < maxChapter {
                nextChapter += 1
                nextVerse = 1
            } else {
                return
            }
        }

        updateVerse(bookCode: nil, chapter: nextChapter, verse: nextVerse)
    }

    func goToPreviousVerse() {
        var prevChapter = currentVerse.chapter
        var prevVerse = currentVerse.verse - 1

        if prevVerse < 1 {
            if prevChapter > 1 {
                prevChapter -= 1
                prevVerse = 1
            } else {
                return
            }
        }

        updateVerse(bookCode: nil, chapter: prevChapter, verse: prevVerse)
    }

    // MARK: - 음성 인식 결과 처리

    /// Whisper/서버에서 들어온 "인식된 문장" 전체를 넣어주면 됨
    func handleRecognizedText(_ fullText: String) {
        let tokens = tokenize(fullText)
        let verseWords = words.map { normalize($0) }

        let matched = matchTokensToVerseWords(
            verseWords: verseWords,
            tokens: tokens
        )

        // 읽힌 단어들을 업데이트
        highlightedWordIndexes.formUnion(matched)
    }
    private func tokenize(_ text: String) -> [String] {
        return text
            .split { $0 == " " || $0 == "," || $0 == "." }
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
    }


    private func splitToWords(_ s: String) -> [String] {
        s.components(separatedBy: .whitespacesAndNewlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func normalize(_ s: String) -> String {
        let lower = s.lowercased()
        let hangul = CharacterSet(charactersIn: "가"..."힣")
        let allowed = hangul.union(.alphanumerics)

        let scalars = lower.unicodeScalars.filter { allowed.contains($0) }
        return String(String.UnicodeScalarView(scalars))
    }

    private func containsHangul(_ s: String) -> Bool {
        for scalar in s.unicodeScalars {
            if scalar.value >= 0xAC00 && scalar.value <= 0xD7A3 {
                return true
            }
        }
        return false
    }

    private func levenshtein(_ a: [Character], _ b: [Character]) -> Int {
        let n = a.count
        let m = b.count
        if n == 0 { return m }
        if m == 0 { return n }

        var dp = Array(repeating: Array(repeating: 0, count: m + 1), count: n + 1)
        for i in 0...n { dp[i][0] = i }
        for j in 0...m { dp[0][j] = j }

        for i in 1...n {
            for j in 1...m {
                if a[i - 1] == b[j - 1] {
                    dp[i][j] = dp[i - 1][j - 1]
                } else {
                    let del = dp[i - 1][j] + 1
                    let ins = dp[i][j - 1] + 1
                    let rep = dp[i - 1][j - 1] + 1
                    dp[i][j] = min(del, ins, rep)
                }
            }
        }
        return dp[n][m]
    }

    
    private func isLooseKoreanMatch(normalizedVerseWord nw: String,
                                    normalizedToken t: String) -> Bool {
        // 공백 제거(혹시 모를 스페이스)
        let nwTrim = nw.replacingOccurrences(of: " ", with: "")
        let tTrim  = t.replacingOccurrences(of: " ", with: "")

        // 0) 완전 일치
        if nwTrim == tTrim { return true }

        // 한글이 전혀 없으면 느슨 매칭 안 함
        guard containsHangul(nwTrim) || containsHangul(tTrim) else {
            return false
        }

        // 0-1) "도륙하고"(nw) vs "도륙"(t),
        //      "창조하시니라"(nw) vs "창조"(t) 같은
        //      [성경 단어] = [어간] + 조사/어미 케이스
        let safeSuffixes: Set<String> = [
            "하고", "하며", "하여", "하면서",
            "하니라", "하도다",
            "하시니라", "하셨느니라",
            "이라고", "라고",
            "이라", "이니라", "이며", "이고"
        ]

        if nwTrim.count > tTrim.count {
            let diff = nwTrim.count - tTrim.count
            // 조사/어미 길이는 최대 4글자까지 허용 (하시니라 4글자 대응)
            if diff > 0 && diff <= 4, nwTrim.hasPrefix(tTrim) {
                let suffix = String(nwTrim.dropFirst(tTrim.count))
                if safeSuffixes.contains(suffix) {
                    return true
                }
            }
        }

        // 필요하면 반대 케이스(STT가 더 길 때)도 열어둘 수 있지만
        // 오탐 위험이 커서 일단 막아둠
        // if tTrim.count > nwTrim.count { ... }

        // 1) 1글자 토큰: 기존 로직 유지
        if tTrim.count == 1 {
            guard let ch = tTrim.first else { return false }

            let naene: Set<Character> = ["내", "네"]
            func inNaene(_ c: Character) -> Bool { naene.contains(c) }

            if nwTrim.count <= 3, let first = nwTrim.first, let last = nwTrim.last {

                if first == ch || last == ch {
                    return true
                }

                if inNaene(ch) && (inNaene(first) || inNaene(last)) {
                    return true
                }

                return false
            } else {
                return false
            }
        }

        // 2) 2글자 이상: 기존 Levenshtein 느슨 매칭
        if nwTrim.count < 2 || tTrim.count < 2 { return false }
        guard let f1 = nwTrim.first, let f2 = tTrim.first, f1 == f2 else {
            return false
        }

        let a = Array(nwTrim)
        let b = Array(tTrim)
        let maxLen = max(a.count, b.count)

        // 길이 차이가 너무 크면(>2) 그대로 다른 단어로 본다.
        // → "도륙하고"(4) vs "도륙"(2) 는 위 suffix 로직에서 이미 처리됨
        if abs(a.count - b.count) > 2 { return false }

        let dist = levenshtein(a, b)
        if maxLen <= 4 {
            return dist <= 1
        } else {
            return dist <= 2
        }
    }

    func matchTokensToVerseWords(verseWords: [String], tokens: [String]) -> Set<Int> {
        var matchedIndexes: Set<Int> = []
        var tokenIndex = 0

        for (i, verseWord) in verseWords.enumerated() {
            guard tokenIndex < tokens.count else { break }

            let t1 = tokens[tokenIndex]
            let single = t1
            let combined: String? = {
                guard tokenIndex + 1 < tokens.count else { return nil }
                return t1 + tokens[tokenIndex + 1]     // "창조" + "하시니라" = "창조하시니라"
            }()

            // 1) 현재 토큰 하나만으로 매칭 시도
            if isLooseKoreanMatch(normalizedVerseWord: verseWord, normalizedToken: single) {
                matchedIndexes.insert(i)
                tokenIndex += 1
                continue
            }

            // 2) 현재 + 다음 토큰을 합쳐서 매칭 시도
            if let comb = combined,
               isLooseKoreanMatch(normalizedVerseWord: verseWord, normalizedToken: comb) {
                matchedIndexes.insert(i)
                tokenIndex += 2   // 두 토큰 소비
                continue
            }

            // 3) 둘 다 안 맞으면 STT 토큰 하나만 넘기고 다음 비교
            tokenIndex += 1
        }

        return matchedIndexes
    }



    private func applyTokens(_ tokens: [String]) {
        let normalizedTokens = tokens
            .map { normalize($0) }
            .filter { !$0.isEmpty }

        for token in normalizedTokens {
            highlightNextOccurrence(of: token)
        }
    }

    private func highlightNextOccurrence(of normalizedToken: String) {
        let t = normalizedToken.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }

        let verseWords = words

        for (index, word) in verseWords.enumerated() {
            if highlightedWordIndexes.contains(index) { continue }

            let nw = normalize(word)
            if nw.isEmpty { continue }

            if isLooseKoreanMatch(normalizedVerseWord: nw, normalizedToken: t) {
                highlightedWordIndexes.insert(index)
                break
            }
        }
    }

    // MARK: - 진행도 + 스토어 연동

    

    // MARK: - 책 이름 한글 매핑

    func localizedBookName(for code: String, fallback: String) -> String {
        let map: [String: String] = [
            "GEN": "창세기","EXO": "출애굽기","LEV": "레위기","NUM": "민수기","DEU": "신명기",
            "JOS": "여호수아","JDG": "사사기","RUT": "룻기","1SA": "사무엘상","2SA": "사무엘하",
            "1KI": "열왕기상","2KI": "열왕기하","1CH": "역대상","2CH": "역대하","EZR": "에스라",
            "NEH": "느헤미야","EST": "에스더","JOB": "욥기","PSA": "시편","PRO": "잠언",
            "ECC": "전도서","SNG": "아가","ISA": "이사야","JER": "예레미야","LAM": "예레미야애가",
            "EZK": "에스겔","DAN": "다니엘","HOS": "호세아","JOL": "요엘","AMO": "아모스",
            "OBA": "오바댜","JON": "요나","MIC": "미가","NAM": "나훔","HAB": "하박국",
            "ZEP": "스바냐","HAG": "학개","ZEC": "스가랴","MAL": "말라기",
            "MAT": "마태복음","MRK": "마가복음","LUK": "누가복음","JHN": "요한복음","ACT": "사도행전",
            "ROM": "로마서","1CO": "고린도전서","2CO": "고린도후서","GAL": "갈라디아서",
            "EPH": "에베소서","PHP": "빌립보서","COL": "골로새서","1TH": "데살로니가전서",
            "2TH": "데살로니가후서","1TI": "디모데전서","2TI": "디모데후서","TIT": "디도서",
            "PHM": "빌레몬서","HEB": "히브리서","JAS": "야고보서","1PE": "베드로전서",
            "2PE": "베드로후서","1JN": "요한일서","2JN": "요한이서","3JN": "요한삼서",
            "JUD": "유다서","REV": "요한계시록"
        ]
        return map[code] ?? fallback
    }

    // MARK: - 카테고리 / 책 목록

    func loadInitialVerse(for category: BibleCategory) {
        selectedCategory = category
        Task {
            await loadBooksIfNeeded()
        }
    }

    func loadBooksIfNeeded() async {
        if !books.isEmpty {
            applyCategoryFilter()
            return
        }

        do {
            let fetched = try await BibleAPI.shared.fetchBooks()
            self.books = fetched

            applyCategoryFilter()

            guard let first = filteredBooks.first ?? fetched.first else { return }

            self.selectedBookCode = first.code
            self.currentVerse = BibleVerse(
                id: "\(first.code)-1-1",
                book: localizedBookName(for: first.code, fallback: first.name),
                chapter: 1,
                verse: 1,
                text: ""
            )

            try await loadCurrentVerseFromServer()
        } catch {
            print("❌ loadBooksIfNeeded error: \(error)")
        }
    }

    func loadCurrentVerseFromServer() async throws {
        guard let bookCode = selectedBookCode, !bookCode.isEmpty else { return }

        do {
            let dto = try await BibleAPI.shared.fetchVerse(
                bookCode: bookCode,
                chapter: currentVerse.chapter,
                verse: currentVerse.verse
            )

            self.currentVerse = BibleVerse(
                id: "\(dto.bookCode)-\(dto.chapter)-\(dto.verse)",
                book: localizedBookName(for: dto.bookCode, fallback: dto.bookCode),
                chapter: dto.chapter,
                verse: dto.verse,
                text: dto.text
            )

            loadHighlightForCurrentVerse()
            recalcBookAndGlobalProgress()
        } catch {
            print("❌ loadCurrentVerseFromServer error: \(error)")
            throw error
        }
    }

    private func applyCategoryFilter() {
        guard !books.isEmpty else {
            filteredBooks = []
            return
        }

        guard let category = selectedCategory else {
            filteredBooks = books
            return
        }

        let all = books

        let newTestamentCodes: Set<String> = [
            "MAT","MRK","LUK","JHN","ACT","ROM",
            "1CO","2CO","GAL","EPH","PHP","COL",
            "1TH","2TH","1TI","2TI","TIT","PHM",
            "HEB","JAS","1PE","2PE","1JN","2JN",
            "3JN","JUD","REV"
        ]
        let gospelCodes: Set<String> = ["MAT", "MRK", "LUK", "JHN"]
        let psalmsProverbsCodes: Set<String> = ["PSA", "PRO"]

        switch category {
        case .whole, .custom:
            filteredBooks = all
        case .gospels:
            filteredBooks = all.filter { gospelCodes.contains($0.code) }
        case .psalmsProverbs:
            filteredBooks = all.filter { psalmsProverbsCodes.contains($0.code) }
        case .newTestament:
            filteredBooks = all.filter { newTestamentCodes.contains($0.code) }
        case .oldTestament:
            filteredBooks = all.filter { !newTestamentCodes.contains($0.code) }
        }
    }
}
