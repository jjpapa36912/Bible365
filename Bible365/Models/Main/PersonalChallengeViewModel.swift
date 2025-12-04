import Foundation

// MARK: - 한 절 단위 모델 (한국어만 사용)

// MARK: - 진행도 모델들 (절 / 책 / 전체)

/// 한 절 기준으로 저장되는 진행 정보
struct VerseProgress: Codable {
    let verseId: String       // "GEN-1-1"
    let bookCode: String      // "GEN"
    var highlightedWordIndexes: [Int]   // 파란색 단어 index들
    var isCompleted: Bool                 // 이 절을 완료로 볼지 여부
}

/// 한 권(책) 기준 진행 요약 (절 개수 기반)
struct BookProgressSummary: Codable {
    let bookCode: String          // 예: "PRO"
    var completedVerseCount: Int  // 이 책에서 완료된 절 수
    var totalVerseCount: Int      // 이 책 전체 절 수
    var completionCount: Int      // 이 책 완독 횟수 (전체 절 다 채웠을 때 증가)
}

/// 전체 성경(66권) 기준 진행 요약 (절 개수 기반)
struct GlobalProgressSummary: Codable {
    var completedVerseCount: Int  // 전체 완료된 절 수
    var totalVerseCount: Int      // 전체 절 수
    var completionCount: Int      // 성경 전체 완독 횟수
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

// MARK: - 진행도 저장소
@MainActor
final class ReadingProgressStore: ObservableObject {
    static let shared = ReadingProgressStore()

    @Published private(set) var profile: ReadingProfile = ReadingProfile()

    private let storageKeyBase = "reading_profile_v3_verseBased"

    private let meta = BibleVerseMetaProvider.shared

    private init() {
        load()
        applyMetaToGlobal()
    }

    private var storageKey: String {
        // 로그인 붙으면 여기에 userId 붙이면 됨
        storageKeyBase
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        do {
            let decoded = try JSONDecoder().decode(ReadingProfile.self, from: data)
            self.profile = decoded
        } catch {
            print("⚠️ ReadingProgressStore load error: \(error)")
        }
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(profile)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("⚠️ ReadingProgressStore save error: \(error)")
        }
    }

    /// 메타에서 전체 절 수를 global에 반영
    private func applyMetaToGlobal() {
        let total = meta.globalTotalVerses
        if total > 0 {
            profile.global.totalVerseCount = total
        }
    }
    
    // MARK: - 디버그: 특정 절만 남기고 전부 읽음 처리

        /// 디버그용: 전체를 "읽음" 상태로 만들어 놓고, 특정 verseId만 미완료로 남긴다.
        /// 예: verseId = "MRK-1-1"
    // MARK: - 디버그: "마가복음 1:1만 빼고 전부 읽음" 상태 만들기
    // MARK: - 디버그: "마가복음 1:1만 빼고 전부 읽음" 상태 만들기
    func debugFillAllAsReadExceptMark11() {
        // 🔹 이전 프로필(기존 회독 수 유지용)
        let oldProfile = self.profile

        var newProfile = ReadingProfile()

        let allBookCodes: [String] = [
            "GEN","EXO","LEV","NUM","DEU","JOS","JDG","RUT",
            "1SA","2SA","1KI","2KI","1CH","2CH","EZR","NEH","EST",
//            "JOB","PSA","PRO","ECC","SNG","ISA","JER","LAM","EZK","DAN",
//            "HOS","JOL","AMO","OBA","JON","MIC","NAM","HAB","ZEP","HAG","ZEC","MAL",
//            "MAT","MRK","LUK","JHN","ACT","ROM",
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

            // 기본은 전체 절 다 읽음
            var completed = total

            // 마가복음만 1절 덜 읽은 상태로
            if code == "MRK" {
                completed = max(0, total - 1)
            }

            totalVerses += total
            totalCompleted += completed

            // 🔹 각 책의 이전 회독 수 유지
            let oldBookCompletion = oldProfile.bookProgressByCode[code]?.completionCount ?? 0

            let summary = BookProgressSummary(
                bookCode: code,
                completedVerseCount: completed,
                totalVerseCount: total,
                completionCount: oldBookCompletion
            )
            newProfile.bookProgressByCode[code] = summary
        }

        // 🔹 글로벌 요약: 기존 회독 수는 그대로 유지
        newProfile.global.totalVerseCount = totalVerses
        newProfile.global.completedVerseCount = totalCompleted
        newProfile.global.completionCount = oldProfile.global.completionCount

        self.profile = newProfile
        save()
    }



    // MARK: - 업데이트

    /// 한 절의 진행 상태 변경
    /// - highlightedIndexes: 파란 단어 인덱스들
    /// - isCompleted: 이 절을 "완료"로 볼지 여부 (ViewModel에서 계산)
    func updateVerseProgress(
        verseId: String,
        bookCode: String,
        highlightedIndexes: Set<Int>,
        isCompleted: Bool
    ) {
        var profile = self.profile

        let newIndexes = Array(highlightedIndexes).sorted()

        let old = profile.verseProgressById[verseId]
        let wasCompleted = old?.isCompleted ?? false

        // verseProgress 갱신
        let vp = VerseProgress(
            verseId: verseId,
            bookCode: bookCode,
            highlightedWordIndexes: newIndexes,
            isCompleted: isCompleted
        )
        profile.verseProgressById[verseId] = vp

        // delta: 완료 여부 변화
        let deltaCompleted = (isCompleted ? 1 : 0) - (wasCompleted ? 1 : 0)

        // --- 책 단위 요약 갱신 ---
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

        // 책 완독 체크: completedVerseCount == totalVerseCount로 딱 맞을 때 1 증가
        if bookSummary.totalVerseCount > 0,
           deltaCompleted > 0,
           bookSummary.completedVerseCount == bookSummary.totalVerseCount {
            bookSummary.completionCount += 1
        }

        profile.bookProgressByCode[bookCode] = bookSummary

        // --- 전체(global) 요약 갱신 ---
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

        // 최종 반영
        self.profile = profile
        save()
    }

    // MARK: - 조회

    /// 특정 절에 대한 저장된 하이라이트 인덱스
    func highlightedIndexes(for verseId: String) -> Set<Int> {
        guard let vp = profile.verseProgressById[verseId] else { return [] }
        return Set(vp.highlightedWordIndexes)
    }

    /// 특정 책(예: "PRO") 기준 진행률 (0.0 ~ 1.0)
    func progressForBook(bookCode: String) -> Double {
        guard let total = meta.totalVerses(for: bookCode), total > 0 else {
            return 0.0
        }
        let completed = profile.bookProgressByCode[bookCode]?.completedVerseCount ?? 0
        return Double(completed) / Double(total)
    }

    /// 전체 성경 기준 진행률
    func globalProgress() -> Double {
        let total = meta.globalTotalVerses
        guard total > 0 else { return 0.0 }
        let completed = profile.global.completedVerseCount
        return Double(completed) / Double(total)
    }

    func completionCountForBook(bookCode: String) -> Int {
        profile.bookProgressByCode[bookCode]?.completionCount ?? 0
    }

    func globalCompletionCount() -> Int {
        profile.global.completionCount
    }

    // MARK: - 전체 리셋

    /// 새 회독을 시작하기 위해 전체 진행도를 초기화
    /// - keepCompletionCounts: true면 완독 횟수는 유지, false면 완전히 0부터
    func resetAllProgress(keepCompletionCounts: Bool) {
        var newProfile = profile

        // 절 단위 진행도 전부 삭제
        newProfile.verseProgressById.removeAll()

        // 책 단위: 완료된 절 수만 0으로, 필요 시 completionCount도 리셋
        newProfile.bookProgressByCode = newProfile.bookProgressByCode.mapValues { summary in
            var s = summary
            s.completedVerseCount = 0
            if !keepCompletionCounts {
                s.completionCount = 0
            }
            return s
        }

        // 전체(global): 완료 절 수만 0으로, 필요 시 completionCount도 리셋
        var global = newProfile.global
        global.completedVerseCount = 0
        if !keepCompletionCounts {
            global.completionCount = 0
        }
        newProfile.global = global

        // 반영 + 저장
        self.profile = newProfile
        save()
    }
}

// MARK: - 뷰 모델 관련 타입들

struct BibleVerse: Identifiable, Equatable {
    let id: String      // 예: "GEN-1-1"
    let book: String    // 책 이름 (한글 표시용)
    let chapter: Int
    let verse: Int
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

    // 1단계: 카테고리
    @Published var selectedCategory: BibleCategory? = nil {
        didSet {
            applyCategoryFilter()
        }
    }
    @Published var didFinishWholeBibleRound: Bool = false

    // 현재 절
    @Published var currentVerse: BibleVerse

    // 현재 절의 단어 인덱스 중, 음성으로 읽힌 것들 (한국어 기준)
    @Published var highlightedWordIndexes: Set<Int> = []

    // 상단 "전체 진행률" → 현재 책 기준 (절 개수 기반)
    @Published var totalProgress: Double = 0.0

    // 성경 전체 기준 진행률 (0.0 ~ 1.0)
    @Published var globalProgressValue: Double = 0.0

    // 마이크 상태
    @Published var isListening: Bool = false

    // 서버에서 받은 "전체" 책 목록
    @Published var books: [BibleBookDTO] = []

    // 현재 카테고리에 따라 필터링된 책 목록 → Picker는 이걸 사용
    @Published var filteredBooks: [BibleBookDTO] = []

    // 선택된 책 코드 (예: "GEN")
    @Published var selectedBookCode: String? = nil

    // 현재 선택된 책/장에 대한 최대 값 (Stepper 범위)
    @Published var maxChapter: Int = 150
    @Published var maxVerse: Int = 176

    // 진행도 저장소
    private let progressStore = ReadingProgressStore.shared

    // 절 완료 판정 threshold (예: 0.9 = 90% 이상 단어가 파란색이면 "읽었다"로 간주)
    private let completionThreshold: Double = 0.9

    // 마지막으로 알고 있던 "전체 완독 횟수"
    private var lastKnownGlobalCompletionCount: Int = 0

    // MARK: - 초기화

    init() {
        self.currentVerse = BibleVerse(
            id: "INIT-1-1",
            book: "",
            chapter: 1,
            verse: 1,
            text: ""
        )

        // 기존 저장된 회독 횟수/전체 진행률 반영
        lastKnownGlobalCompletionCount = progressStore.globalCompletionCount()
        recalcBookAndGlobalProgress()

        // 혹시 INIT-1-1 같은 것도 저장돼 있을 수 있으니 시도만
        loadHighlightForCurrentVerse()
    }

    // MARK: - 현재 절 단어/진행률

    /// 한국어 본문을 공백 기준으로 나눈 단어 배열
    var words: [String] {
        splitToWords(currentVerse.text)
    }

    /// 현재 절 진행률 (단어 기준 0.0 ~ 1.0)
    var verseProgress: Double {
        guard !words.isEmpty else { return 0 }
        return Double(highlightedWordIndexes.count) / Double(words.count)
    }

    /// 현재 절을 "완료"로 볼지 여부 (threshold 이상이면 true)
    private func isCurrentVerseCompleted() -> Bool {
        guard !words.isEmpty else { return false }
        return verseProgress >= completionThreshold
    }

    /// verseId에서 bookCode 추출 (예: "PRO-1-1" -> "PRO")
    private func bookCode(from verseId: String) -> String {
        verseId.split(separator: "-").first.map(String.init) ?? ""
    }

    /// 보드에서 사용할 책 진행률 래핑
    func progressForBook(_ bookCode: String) -> Double {
        progressStore.progressForBook(bookCode: bookCode)
    }

    // MARK: - 카테고리 초기 세팅

    func loadInitialVerse(for category: BibleCategory) {
        Task {
            await loadBooksIfNeeded()
        }
    }

    // MARK: - 책 목록 최초 1회 로딩

    func loadBooksIfNeeded() async {
        if !books.isEmpty {
            applyCategoryFilter()
            return
        }

        do {
            let fetched = try await BibleAPI.shared.fetchBooks()
            self.books = fetched

            // 카테고리 기준 필터
            applyCategoryFilter()

            // 필터 후 첫 책 선택
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

    // MARK: - 서버에서 실제 성경 구절 로딩

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

            // 절이 바뀌면: 저장된 하이라이트 복원 + 진행률 갱신
            loadHighlightForCurrentVerse()
            recalcBookAndGlobalProgress()
        } catch {
            print("❌ loadCurrentVerseFromServer error: \(error)")
            throw error
        }
    }

    /// 책 / 장 / 절 변경 (책 코드는 optional)
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

    // MARK: - 절 네비게이션

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
    func handleRecognizedText(_ text: String) {
        let tokens = splitToWords(text)
        applyTokens(tokens)
        recalcAndPersistProgress()
    }

    // MARK: - 내부 로직 (토큰 처리 / 정규화)

    private func splitToWords(_ s: String) -> [String] {
        s.components(separatedBy: .whitespacesAndNewlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    /// 비교용 정규화: 한글/영문/숫자만 남기고 나머지(공백·문장부호 등)는 제거
    private func normalize(_ s: String) -> String {
        let lower = s.lowercased()

        let allowed = CharacterSet(
            charactersIn: "가"..."힣"
        ).union(.alphanumerics)

        let scalars = lower.unicodeScalars.filter { allowed.contains($0) }
        return String(String.UnicodeScalarView(scalars))
    }

    // MARK: - 느슨한 한글 매칭 유틸

    /// 문자열에 한글(가~힣)이 하나라도 포함되어 있는지
    private func containsHangul(_ s: String) -> Bool {
        for scalar in s.unicodeScalars {
            if scalar.value >= 0xAC00 && scalar.value <= 0xD7A3 {
                return true
            }
        }
        return false
    }

    /// 두 단어가 "발음 기준으로 비슷한지" 판단
    private func isLooseKoreanMatch(normalizedVerseWord nw: String,
                                    normalizedToken t: String) -> Bool {
        // 1) 완전 일치
        if nw == t { return true }

        // 2) 한글 기반 느슨 매칭만 적용
        if containsHangul(nw) || containsHangul(t) {

            // 🔹 (A) 토큰이 1글자일 때
            if t.count == 1 {
                guard let ch = t.first else { return false }

                let naeneGroup: Set<Character> = ["내", "네"]
                func inNaeneGroup(_ c: Character) -> Bool {
                    naeneGroup.contains(c)
                }

                if nw.count <= 3, let first = nw.first, let last = nw.last {

                    if first == ch || last == ch {
                        return true
                    }

                    if inNaeneGroup(ch) &&
                        (inNaeneGroup(first) || inNaeneGroup(last)) {
                        return true
                    }

                    return false
                } else {
                    return false
                }
            }

            // 🔹 (B) 일반적인 2글자 이상 토큰
            if nw.count < 2 || t.count < 2 { return false }

            guard let f1 = nw.first, let f2 = t.first, f1 == f2 else {
                return false
            }

            let a = Array(nw)
            let b = Array(t)
            let maxLen = max(a.count, b.count)

            if abs(a.count - b.count) > 2 { return false }

            let dist = levenshtein(a, b)

            if maxLen <= 4 {
                return dist <= 1
            } else {
                return dist <= 2
            }
        }

        return false
    }

    /// 간단한 Levenshtein 거리 (편집 거리)
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

    private func applyTokens(_ tokens: [String]) {
        let normalizedTokens = tokens
            .map { normalize($0) }
            .filter { !$0.isEmpty }

        for token in normalizedTokens {
            highlightNextOccurrence(of: token)
        }
    }

    /// 아직 색칠되지 않은 동일 단어의 "가장 앞 인덱스"만 찾아서 하이라이트
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

    // MARK: - 진행도 계산 + 저장소 연동

    /// 책 진행률/절 완료 여부를 다시 계산하고 저장
    private func recalcAndPersistProgress() {
        let verseId = currentVerse.id
        let code = bookCode(from: verseId)
        let isCompleted = isCurrentVerseCompleted()

        // 저장소에 반영
        progressStore.updateVerseProgress(
            verseId: verseId,
            bookCode: code,
            highlightedIndexes: highlightedWordIndexes,
            isCompleted: isCompleted
        )

        // 상단 "책 진행률" + 전체 진행률 다시 계산
        recalcBookAndGlobalProgress()

        // 전체 1회독 완료 여부 체크 후, 완료라면 자동 리셋
        checkAndResetIfFinishedWholeBible()
    }

    /// 상단 책 기준 진행률 + 전체 진행률 동시 갱신
    private func recalcBookAndGlobalProgress() {
        let code = bookCode(from: currentVerse.id)
        totalProgress = progressStore.progressForBook(bookCode: code)
        globalProgressValue = progressStore.globalProgress()
    }

    /// 현재 절에 대해 저장된 하이라이트 인덱스 복원
    private func loadHighlightForCurrentVerse() {
        let stored = progressStore.highlightedIndexes(for: currentVerse.id)
        highlightedWordIndexes = stored
    }

    /// 성경 전체 1회독이 새로 완료되었는지 감지 후, 진행률 리셋
    /// 성경 전체 1회독이 새로 완료되었는지 감지
    /// ➜ 여기서는 "플래그만 올리고", 실제 리셋은 View 쪽에서 Alert 닫을 때 실행
    private func checkAndResetIfFinishedWholeBible() {
        let currentCount = progressStore.globalCompletionCount()
        guard currentCount > lastKnownGlobalCompletionCount else { return }

        // 이전보다 증가했다 = 새로 1회독 완료
        lastKnownGlobalCompletionCount = currentCount

        // 뷰에서 Alert 띄우도록 플래그 ON
        didFinishWholeBibleRound = true
    }

    /// 외부(팀/개인 화면)에서 호출할 수 있는 래퍼
       func checkAndResetIfFinishedPersonal() {
           checkAndResetIfFinishedWholeBible()
       }
    /// 새 회독을 시작하기 위해 전체 진행도를 초기화 (뷰에서도 직접 호출 가능)
    func resetAllProgressForNewRound() {
        progressStore.resetAllProgress(keepCompletionCounts: true)

        // 뷰모델 상태도 초기화
        highlightedWordIndexes.removeAll()
        totalProgress = 0.0
        globalProgressValue = 0.0

        // 현재 절에 대한 하이라이트도 비워졌으므로 다시 로드
        loadHighlightForCurrentVerse()
    }

    /// 팀 챌린지에서 "1독 완료" 시 강제로 호출할 수 있는 메서드
    func forceResetAllProgressForNewRoundFromTeam() {
        resetAllProgressForNewRound()
    }
    /// 디버그용: "마가복음 1:1만 남기고 나머지는 모두 읽음" 상태로 강제 세팅
        func debugMarkAllAsReadExceptMark11() {
            let targetVerseId = "MRK-1-1"

            // 스토어에 디버그 세팅
            progressStore.debugFillAllAsReadExceptMark11()

            // 내부 상태 동기화
            lastKnownGlobalCompletionCount = progressStore.globalCompletionCount()
            globalProgressValue = progressStore.globalProgress()
            totalProgress = progressStore.progressForBook(bookCode: "MRK")

            // 현재 절을 마가복음 1:1로 이동
            selectedBookCode = "MRK"
            currentVerse = BibleVerse(
                id: targetVerseId,
                book: localizedBookName(for: "MRK", fallback: "마가복음"),
                chapter: 1,
                verse: 1,
                text: currentVerse.text    // 실제 본문은 서버에서 다시 로드
            )
            highlightedWordIndexes.removeAll()

            Task {
                try? await loadCurrentVerseFromServer()
            }
        }
    // MARK: - 책 이름 한글 매핑

    func localizedBookName(for code: String, fallback: String) -> String {
        let map: [String: String] = [
            "GEN": "창세기",
            "EXO": "출애굽기",
            "LEV": "레위기",
            "NUM": "민수기",
            "DEU": "신명기",
            "JOS": "여호수아",
            "JDG": "사사기",
            "RUT": "룻기",
            "1SA": "사무엘상",
            "2SA": "사무엘하",
            "1KI": "열왕기상",
            "2KI": "열왕기하",
            "1CH": "역대상",
            "2CH": "역대하",
            "EZR": "에스라",
            "NEH": "느헤미야",
            "EST": "에스더",
            "JOB": "욥기",
            "PSA": "시편",
            "PRO": "잠언",
            "ECC": "전도서",
            "SNG": "아가",
            "ISA": "이사야",
            "JER": "예레미야",
            "LAM": "예레미야애가",
            "EZK": "에스겔",
            "DAN": "다니엘",
            "HOS": "호세아",
            "JOL": "요엘",
            "AMO": "아모스",
            "OBA": "오바댜",
            "JON": "요나",
            "MIC": "미가",
            "NAM": "나훔",
            "HAB": "하박국",
            "ZEP": "스바냐",
            "HAG": "학개",
            "ZEC": "스가랴",
            "MAL": "말라기",

            "MAT": "마태복음",
            "MRK": "마가복음",
            "LUK": "누가복음",
            "JHN": "요한복음",
            "ACT": "사도행전",
            "ROM": "로마서",
            "1CO": "고린도전서",
            "2CO": "고린도후서",
            "GAL": "갈라디아서",
            "EPH": "에베소서",
            "PHP": "빌립보서",
            "COL": "골로새서",
            "1TH": "데살로니가전서",
            "2TH": "데살로니가후서",
            "1TI": "디모데전서",
            "2TI": "디모데후서",
            "TIT": "디도서",
            "PHM": "빌레몬서",
            "HEB": "히브리서",
            "JAS": "야고보서",
            "1PE": "베드로전서",
            "2PE": "베드로후서",
            "1JN": "요한일서",
            "2JN": "요한이서",
            "3JN": "요한삼서",
            "JUD": "유다서",
            "REV": "요한계시록"
        ]
        return map[code] ?? fallback
    }

    // MARK: - 카테고리 필터링

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

        if let first = filteredBooks.first {
            if !filteredBooks.contains(where: { $0.code == selectedBookCode }) {
                selectedBookCode = first.code
            }
        }
    }
}
