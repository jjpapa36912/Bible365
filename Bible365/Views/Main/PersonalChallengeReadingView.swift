import SwiftUI
import Speech

// MARK: - 개인 / 팀 모드

// MARK: - 개인 / 팀 모드

enum BibleProgressMode: Equatable {
    case personal
    case team(teamId: Int, name: String)

    var isPersonal: Bool {
        if case .personal = self { return true }
        return false
    }

    var teamId: Int? {
        if case let .team(id, _) = self { return id }
        return nil
    }

    var displayName: String {
        switch self {
        case .personal:
            return "개인"
        case .team(_, let name):
            return name
        }
    }
}



// MARK: - 66권 정보

struct BibleBook: Identifiable {
    let id: Int          // 0 ~ 65
    let code: String     // "GEN" ...
    let nameKo: String   // "창세기"
}

struct BibleBookProgress: Identifiable {
    let id: Int
    let book: BibleBook
    var progress: Double   // 0.0 ~ 1.0
}

struct BibleBooks {
    static let all: [BibleBook] = [
        // 구약
        .init(id: 0,  code: "GEN", nameKo: "창세기"),
        .init(id: 1,  code: "EXO", nameKo: "출애굽기"),
        .init(id: 2,  code: "LEV", nameKo: "레위기"),
        .init(id: 3,  code: "NUM", nameKo: "민수기"),
        .init(id: 4,  code: "DEU", nameKo: "신명기"),
        .init(id: 5,  code: "JOS", nameKo: "여호수아"),
        .init(id: 6,  code: "JDG", nameKo: "사사기"),
        .init(id: 7,  code: "RUT", nameKo: "룻기"),
        .init(id: 8,  code: "1SA", nameKo: "사무엘상"),
        .init(id: 9,  code: "2SA", nameKo: "사무엘하"),
        .init(id: 10, code: "1KI", nameKo: "열왕기상"),
        .init(id: 11, code: "2KI", nameKo: "열왕기하"),
        .init(id: 12, code: "1CH", nameKo: "역대상"),
        .init(id: 13, code: "2CH", nameKo: "역대하"),
        .init(id: 14, code: "EZR", nameKo: "에스라"),
        .init(id: 15, code: "NEH", nameKo: "느헤미야"),
        .init(id: 16, code: "EST", nameKo: "에스더"),
        .init(id: 17, code: "JOB", nameKo: "욥기"),
        .init(id: 18, code: "PSA", nameKo: "시편"),
        .init(id: 19, code: "PRO", nameKo: "잠언"),
        .init(id: 20, code: "ECC", nameKo: "전도서"),
        .init(id: 21, code: "SNG", nameKo: "아가"),
        .init(id: 22, code: "ISA", nameKo: "이사야"),
        .init(id: 23, code: "JER", nameKo: "예레미야"),
        .init(id: 24, code: "LAM", nameKo: "예레미야애가"),
        .init(id: 25, code: "EZK", nameKo: "에스겔"),
        .init(id: 26, code: "DAN", nameKo: "다니엘"),
        .init(id: 27, code: "HOS", nameKo: "호세아"),
        .init(id: 28, code: "JOL", nameKo: "요엘"),
        .init(id: 29, code: "AMO", nameKo: "아모스"),
        .init(id: 30, code: "OBA", nameKo: "오바댜"),
        .init(id: 31, code: "JON", nameKo: "요나"),
        .init(id: 32, code: "MIC", nameKo: "미가"),
        .init(id: 33, code: "NAM", nameKo: "나훔"),
        .init(id: 34, code: "HAB", nameKo: "하박국"),
        .init(id: 35, code: "ZEP", nameKo: "스바냐"),
        .init(id: 36, code: "HAG", nameKo: "학개"),
        .init(id: 37, code: "ZEC", nameKo: "스가랴"),
        .init(id: 38, code: "MAL", nameKo: "말라기"),
        // 신약
        .init(id: 39, code: "MAT", nameKo: "마태복음"),
        .init(id: 40, code: "MRK", nameKo: "마가복음"),
        .init(id: 41, code: "LUK", nameKo: "누가복음"),
        .init(id: 42, code: "JHN", nameKo: "요한복음"),
        .init(id: 43, code: "ACT", nameKo: "사도행전"),
        .init(id: 44, code: "ROM", nameKo: "로마서"),
        .init(id: 45, code: "1CO", nameKo: "고린도전서"),
        .init(id: 46, code: "2CO", nameKo: "고린도후서"),
        .init(id: 47, code: "GAL", nameKo: "갈라디아서"),
        .init(id: 48, code: "EPH", nameKo: "에베소서"),
        .init(id: 49, code: "PHP", nameKo: "빌립보서"),
        .init(id: 50, code: "COL", nameKo: "골로새서"),
        .init(id: 51, code: "1TH", nameKo: "데살로니가전서"),
        .init(id: 52, code: "2TH", nameKo: "데살로니가후서"),
        .init(id: 53, code: "1TI", nameKo: "디모데전서"),
        .init(id: 54, code: "2TI", nameKo: "디모데후서"),
        .init(id: 55, code: "TIT", nameKo: "디도서"),
        .init(id: 56, code: "PHM", nameKo: "빌레몬서"),
        .init(id: 57, code: "HEB", nameKo: "히브리서"),
        .init(id: 58, code: "JAS", nameKo: "야고보서"),
        .init(id: 59, code: "1PE", nameKo: "베드로전서"),
        .init(id: 60, code: "2PE", nameKo: "베드로후서"),
        .init(id: 61, code: "1JN", nameKo: "요한1서"),
        .init(id: 62, code: "2JN", nameKo: "요한2서"),
        .init(id: 63, code: "3JN", nameKo: "요한3서"),
        .init(id: 64, code: "JUD", nameKo: "유다서"),
        .init(id: 65, code: "REV", nameKo: "요한계시록")
    ]
}
// BibleBooks.swift (이미 있을 거라 가정, 거기에 extension 추가)

extension BibleBooks {
    static func book(forIndex index: Int) -> BibleBook? {
        guard index >= 0, index < all.count else { return nil }
        return all[index]
    }
}

// B I B L E 열별 인덱스 (레터 실루엣 느낌만 유지)
struct BibleBoardLayout {
    static let columns: [[Int]] = [
        Array(0..<15),   // B
        Array(15..<27),  // I
        Array(27..<42),  // B
        Array(42..<53),  // L
        Array(53..<66)   // E
    ]
}

// MARK: - 한 권 블럭 (칸 + 빛)

struct BibleBookBlockView: View {
    let progress: BibleBookProgress
    let isCurrent: Bool

    var body: some View {
           GeometryReader { geo in
               ZStack {
                   // 배경
                   RoundedRectangle(cornerRadius: 12)
                       .fill(Color.white.opacity(0.10))

                   // 🚀 [수정] 0.0001이라도 있으면 최소 15% 길이 보장
                   if progress.progress > 0 {
                       // 실제 비율(raw)과 0.15 중 큰 값 선택
                       let visualProgress = max(progress.progress, 0.15)
                       // 100%를 넘지 않도록 min 처리
                       let width = geo.size.width * CGFloat(min(visualProgress, 1.0))

                       RoundedRectangle(cornerRadius: 12)
                           .fill(
                               LinearGradient(
                                   colors: [Color.yellow.opacity(0.8), Color.white.opacity(0.0)],
                                   startPoint: .leading, endPoint: .trailing
                               )
                           )
                           .frame(width: width, height: geo.size.height) // 🔹 계산된 너비 적용
                           .shadow(color: Color.yellow.opacity(0.5), radius: 8)
                           .mask(RoundedRectangle(cornerRadius: 12))
                           .frame(maxWidth: .infinity, alignment: .leading)
                   }

                   // 텍스트
                   Text(progress.book.nameKo)
                       .font(.system(size: 11, weight: .semibold))
                       .foregroundColor(.white)
                       .padding(.horizontal, 8)
               }
           }
           .frame(height: 28)
       }
}

// MARK: - 전체 BIBLE 보드 (이미지 없이 순수 SwiftUI)

struct BibleProgressBoardView: View {

    let mode: BibleProgressMode
    let books: [BibleBookProgress]          // 66개
    let currentBookCode: String?
    var onTapBook: ((BibleBookProgress) -> Void)? = nil

    private var overallProgress: Double {
        guard !books.isEmpty else { return 0 }
        let sum = books.reduce(0) { $0 + $1.progress }
        return sum / Double(books.count)
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.02, green: 0.34, blue: 0.87),
                    Color(red: 0.13, green: 0.54, blue: 0.96)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                header

                GeometryReader { geo in
                    let columnWidth = geo.size.width / 5.4

                    HStack(spacing: 12) {
                        ForEach(0..<BibleBoardLayout.columns.count, id: \.self) { columnIndex in
                            let indices = BibleBoardLayout.columns[columnIndex]
                            let columnBooks = indices.compactMap { idx in
                                books.first(where: { $0.book.id == idx })
                            }

                            ZStack {
                                RoundedRectangle(cornerRadius: columnIndex == 0 || columnIndex == 2 ? 40 : 18)
                                    .fill(Color.white.opacity(0.06))

                                VStack(spacing: 6) {
                                    ForEach(columnBooks) { bp in
                                        Button {
                                            onTapBook?(bp)
                                        } label: {
                                            BibleBookBlockView(
                                                progress: bp,
                                                isCurrent: bp.book.code == currentBookCode
                                            )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal, 4)
                            }
                            .frame(width: columnWidth)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .top)
                }
                .frame(height: 340)
                .frame(minHeight: 340)

                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 32)
            .padding(.bottom, 80)   // ⬅️ **요거 추가: footer 높이보다 넉넉하게**
        }
        .safeAreaInset(edge: .bottom) {
            footer
                .padding(.horizontal, 24)
                .padding(.bottom, 12)
        }
    }


    // MARK: - Header / Footer

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(titleText)
                    .font(.headline)
                    .foregroundColor(.white)
                Text(subtitleText)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(overallProgress * 100))%")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                Text("전체 진행률")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
    }

    private var footer: some View {
        HStack(spacing: 10) {
            ProgressView(value: overallProgress)
                .tint(.yellow)
                .background(Color.white.opacity(0.15))
                .clipShape(Capsule())

            Text(progressComment)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.9))
        }
    }

    private var titleText: String {
        switch mode {
        case .personal: return "나의 Bible 365"
        case .team(let name): return "\(name) 팀 챌린지"
        }
    }

    private var subtitleText: String {
        switch mode {
        case .personal: return "성경 66권 진행률 보드"
        case .team:     return "팀 전체 진행률 보드"
        }
    }

    private var progressComment: String {
        let p = overallProgress
        switch p {
        case 0..<0.05:   return "이제 막 시작했어요."
        case 0.05..<0.3: return "말씀이 조금씩 채워지고 있어요."
        case 0.3..<0.7:  return "꾸준함이 빛나고 있어요."
        case 0.7..<0.99: return "거의 끝이 보입니다!"
        default:         return "축하합니다! 66권 완료 🎉"
        }
    }
}

// MARK: - 메인 개인 챌린지 뷰

struct PersonalChallengeReadingView: View {
    // MARK: - 입력 파라미터
    let mode: BibleProgressMode
       let preselectedBook: BibleBook?
       let initialVerseId: String?

    @StateObject private var vm: PersonalChallengeViewModel
       @StateObject private var speech = SpeechRecognizer()

       @State private var step: PersonalChallengeStep = .selectCategory
       @State private var showFinishAlert = false
       @State private var showBibleBoard = false

    init(
           mode: BibleProgressMode = .personal,
           preselectedBook: BibleBook? = nil,
           initialVerseId: String? = nil
       ) {
           _vm = StateObject(
               wrappedValue: PersonalChallengeViewModel(mode: mode)
           )
           self.mode = mode
           self.preselectedBook = preselectedBook
           self.initialVerseId = initialVerseId

           _vm = StateObject(wrappedValue: PersonalChallengeViewModel(mode: mode))
       }



    var body: some View {
            NavigationStack {
                Group {
                    switch step {
                    case .selectCategory:
                        categorySelectView
                    case .selectVerse:
                        verseSelectView
                    case .reading:
                        readingView
                    }
                }
                .navigationBarHidden(true)
            }
            .task { await initializeFlow() }
        
//        Button("테스트: 마가복음 1:1만 남기기") {
//            vm.debugMarkAllAsReadExceptMark11()
//        }

        .sheet(isPresented: $showBibleBoard) {
            let progresses = personalBookProgress
            BibleProgressBoardView(
                mode: mode,
                books: progresses,
                currentBookCode: currentBookCodeForBoard
            ) { tapped in
                // 책 탭하면 해당 책 1장 1절로 이동
                if let book = vm.filteredBooks.first(where: { $0.code == tapped.book.code }) {
                    vm.selectedBookCode = book.code
                    vm.updateVerse(bookCode: book.code, chapter: 1, verse: 1)
                    step = .reading
                }
            }
        }
        .onChange(of: vm.didFinishWholeBibleRound) { newValue in
            if newValue {
                showFinishAlert = true
                // 알림은 띄워두고, 실제 리셋은 Alert 버튼에서 실행
            }
        }
        .alert("1회독 완료!", isPresented: $showFinishAlert) {
            Button("확인", role: .cancel) {
                // 🔹 여기서 실제 전체 리셋 수행
                vm.resetAllProgressForNewRound()
                // 플래그 리셋
                vm.didFinishWholeBibleRound = false
            }
        } message: {
            Text("축하합니다! 성경 1회독을 완료했어요.")
        }
            
        .task {
                // 1) 이어읽기로 들어온 경우가 최우선
                if let verseId = initialVerseId {
                    await vm.jumpToVerse(verseId: verseId)
                    await MainActor.run {
                        step = .reading
                    }
                    return
                }

                // 2) 팀 챌린지에서 "내가 맡은 책"으로 들어온 경우
                if let preBook = preselectedBook {
                    await vm.loadBooksIfNeeded()
                    await MainActor.run {
                        vm.selectedBookCode = preBook.code
                        vm.updateVerse(bookCode: preBook.code, chapter: 1, verse: 1)
                        step = .reading
                    }
                }
            }


    }
    private func initializeFlow() async {

            // 1) 이어읽기
            if let vId = initialVerseId {
                await vm.jumpToVerse(verseId: vId)
                step = .reading
                return
            }

            // 2) 팀 챌린지에서 특정 책으로 들어온 경우
            if let book = preselectedBook {
                await vm.loadBooksIfNeeded()
                vm.selectedBookCode = book.code
                vm.updateVerse(bookCode: book.code, chapter: 1, verse: 1)
                step = .reading
                return
            }
        }
    // 현재 책 코드 (보드 하이라이트용)
    private var currentBookCodeForBoard: String? {
        let currentName = vm.currentVerse.book
        return BibleBooks.all.first(where: { $0.nameKo == currentName })?.code
    }

    // 책별 진행률 – ReadingProgressStore 기반
    private var personalBookProgress: [BibleBookProgress] {
        BibleBooks.all.map { book in
            let progress = vm.progressForBook(book.code)
            return BibleBookProgress(id: book.id,
                                     book: book,
                                     progress: progress)
        }
    }

    // MARK: - 1단계: 카테고리 선택

    private var categorySelectView: some View {
        CategorySelectView { category in
            vm.selectedCategory = category
            if category == .custom {
                step = .selectVerse
            } else {
                vm.loadInitialVerse(for: category)
                step = .selectVerse
            }
        }
    }

    // MARK: - 2단계: 책/장/절 선택

    private var verseSelectView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Button { step = .selectCategory } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .bold))
                }
                Spacer()
                Text("읽을 구절 선택")
                    .font(.headline)
                Spacer()
                Spacer().frame(width: 24)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)

            Text("어느 책, 장, 절부터 암송 챌린지를 시작할까요?")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal, 20)

            Form {
                Picker("책", selection: $vm.selectedBookCode) {
                    ForEach(vm.filteredBooks) { book in
                        Text(vm.localizedBookName(for: book.code, fallback: book.name))
                            .tag(book.code)
                    }
                }
                .onChange(of: vm.selectedBookCode) { newCode in
                    vm.updateVerse(bookCode: newCode, chapter: 1, verse: 1)
                }

                Stepper(
                    value: Binding(
                        get: { vm.currentVerse.chapter },
                        set: { vm.updateVerse(bookCode: nil, chapter: $0, verse: vm.currentVerse.verse) }
                    ),
                    in: 1...max(vm.maxChapter, 1)
                ) {
                    Text("장: \(vm.currentVerse.chapter)")
                }

                Stepper(
                    value: Binding(
                        get: { vm.currentVerse.verse },
                        set: { vm.updateVerse(bookCode: nil, chapter: vm.currentVerse.chapter, verse: $0) }
                    ),
                    in: 1...max(vm.maxVerse, 1)
                ) {
                    Text("절: \(vm.currentVerse.verse)")
                }
            }

            Button {
                step = .reading
            } label: {
                Text("이 절로 챌린지 시작하기")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(16)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
            }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .task {
            await vm.loadBooksIfNeeded()
        }
    }

    // MARK: - 3단계: 읽기 화면

    private var readingView: some View {
        VStack(spacing: 0) {
            header
            Divider().opacity(0.0)
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    verseInfoSection
                    verseCard
                    micSection
                    navButtons
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .onAppear {
            speech.requestAuthorization()
            // 🔹 읽기 화면 들어온 시점의 절을 이어읽기로 저장
            sendLastReadPosition()
        }
        .onChange(of: vm.currentVerse.id) { _ in
            // 🔹 절 이동(이전/다음, 책 변경)할 때마다 저장
            sendLastReadPosition()
            // 2. 🔹 [수정된 부분] 마이크가 켜져 있다면 STT 세션 재시작 호출
            if vm.isListening {
                restartSTTSessionIfNeeded()
            }
        }
    }

    // PersonalChallengeReadingView 내부

    // MARK: - STT 재시작 헬퍼
    private func restartSTTSessionIfNeeded() {
        guard vm.isListening else { return }
        
        print("🔄 절 변경 -> STT 세션 재시작")

        // 1) 기존 STT 세션 정리 (SpeechRecognizer 내부 stop 호출)
        speech.stop()

        // 2) 아주 짧은 딜레이 후 재시작 (AudioEngine 충돌 방지)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            // 딜레이 동안 사용자가 멈췄을 수도 있으므로 재확인
            guard vm.isListening else { return }
            
            speech.start { text in
                Task { @MainActor in
                    vm.handleRecognizedText(text)
                }
            }
        }
    }
    // MARK: - 헤더
    private func sendLastReadPosition() {
        let verseId = vm.currentVerse.id

        Task {
            do {
                switch mode {
                case .personal:
                    try await BibleAPI.shared.updateLastReadPosition(
                        verseId: verseId,
                        mode: "personal",
                        teamId: nil,
                        teamName: nil
                    )

                case .team(let id, let name):
                    try await BibleAPI.shared.updateLastReadPosition(
                        verseId: verseId,
                        mode: "team",
                        teamId: id,
                        teamName: name
                    )
                }

                print("✅ updateLastReadPosition 성공")

            } catch APIError.unauthorized {
                print("❌ lastReadPosition: 401 (로그인 필요)")
            } catch {
                print("❌ updateLastReadPosition 오류: \(error)")
            }
        }
    }



    // MARK: - 헤더
    private func modeString() -> String {
        switch mode {
        case .personal:
            return "personal"
        case .team:
            return "team"
        }
    }

    private var headerTitle: String {
        switch mode {
        case .personal:
            return "개인 챌린지"
        case .team(let name):
            return "팀 챌린지 (\(name))"
        }
    }


    private var headerSubtitle: String? {
        if case let .team(_, name) = mode {
            return name
        }
        return nil
    }




    private var header: some View {
        ZStack {
            Color.blue
                .ignoresSafeArea(edges: .top)
                .frame(height: 120)

            VStack(spacing: 12) {
                HStack {
                    Button { step = .selectVerse } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    }

                    Spacer()

                    VStack(spacing: 2) {
                        Text(headerTitle)
                            .foregroundColor(.white)
                            .font(.headline)


                        if let subtitle = headerSubtitle {
                            Text(subtitle)
                                .foregroundColor(.white.opacity(0.8))
                                .font(.caption)
                        }
                    }

                    Spacer()

                    HStack(spacing: 12) {
                        Button { showBibleBoard = true } label: {
                            Image(systemName: "square.grid.3x3.fill")
                                .foregroundColor(.white)
                        }
                        Button(action: {}) {
                            Image(systemName: "ellipsis")
                                .rotationEffect(.degrees(90))
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(.horizontal, 20)

                VStack(spacing: 4) {
                    Text("전체 진행률")
                        .foregroundColor(.white.opacity(0.8))
                        .font(.caption)

                    ProgressView(value: vm.totalProgress)
                        .accentColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 20)

                    Text("\(Int(vm.totalProgress * 100))%")
                        .foregroundColor(.white)
                        .font(.caption)
                }
            }
            .padding(.bottom, 8)
        }
    }

    // MARK: - 본문/마이크/내비

    private var verseInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(vm.currentVerse.book) \(vm.currentVerse.chapter)장 \(vm.currentVerse.verse)절")
                    .font(.title3)
                    .fontWeight(.semibold)
                Spacer()
                Button { step = .selectVerse } label: {
                    Text("다른 절 선택")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }

            HStack(spacing: 8) {
                Text("이 절 진행률")
                    .font(.caption)
                    .foregroundColor(.secondary)
                ProgressView(value: vm.verseProgress)
                    .frame(maxWidth: .infinity)
                Text("\(Int(vm.verseProgress * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var verseCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("본문")
                .font(.caption)
                .foregroundColor(.secondary)

            verseTextView
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(UIColor.secondarySystemBackground))  // ✅ 시스템 색
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
        }
    }


    private var verseTextView: some View {
        Text(koreanAttributedVerse)
            .font(.title3)
            .foregroundColor(.primary)   // ✅ 기본 텍스트 색은 여기서
            .lineSpacing(6)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var koreanAttributedVerse: AttributedString {
        var result = AttributedString("")
        for (idx, word) in vm.words.enumerated() {
            let isOn = vm.highlightedWordIndexes.contains(idx)
            let prefix = idx == 0 ? "" : " "
            var part = AttributedString(prefix + word)

            if isOn {
                // ✅ 강조 단어만 색/배경 지정
                part.foregroundColor = .blue
                part.backgroundColor = Color.blue.opacity(0.09)
            }
            // ❌ else 에서 .primary 지정하지 않음
            //    -> 기본 색은 위의 Text에서 .primary 로 통일

            result += part
        }
        return result
    }

    private var micSection: some View {
        VStack(spacing: 12) {
            Text("음성을 인식하여 읽은 단어가 파란색으로 표시됩니다.")
                .font(.footnote)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)

            HStack(spacing: 24) {
                Spacer()
                Button {
                    if vm.isListening {
                        vm.isListening = false
                        speech.stop()
                    } else {
                        vm.isListening = true
                        speech.start { text in
                            Task { @MainActor in
                                vm.handleRecognizedText(text)
                            }
                        }
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(vm.isListening ? Color.red : Color.blue)
                            .frame(width: 72, height: 72)
                        Image(systemName: vm.isListening ? "stop.fill" : "mic.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 26, weight: .bold))
                    }
                }
                Spacer()
            }
            .padding(.top, 4)
        }
    }

    private var navButtons: some View {
        HStack(spacing: 16) {
            Button {
                vm.goToPreviousVerse()
            } label: {
                Text("이전 절")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(.systemGray5))
                    .foregroundColor(.primary)
                    .cornerRadius(16)
            }
            Button {
                vm.goToNextVerse()
            } label: {
                Text("다음 절")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(16)
            }
        }
        .padding(.top, 16)
    }
}

// MARK: - 카테고리 선택 뷰

struct CategorySelectView: View {
    let onSelect: (BibleCategory) -> Void
    
    // 🔹 상위 화면(네비게이션 pop / sheet dismiss)을 위한 환경 값
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack {
                Button {
                    // 🔹 이전 화면으로 돌아가기
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)      // ✅ 라이트/다크 모두 잘 보이게
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            
            Text("챌린지 시작")
                .font(.largeTitle)
                .bold()
                .foregroundColor(.primary)              // ✅ 제목 색 고정
                .padding(.horizontal, 20)
            
            Text("먼저 어떤 범위로 말씀을 읽을지 선택해 주세요.")
                .font(.subheadline)
                .foregroundColor(.secondary)            // ✅ 설명은 세컨더리
                .padding(.horizontal, 20)
            
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(BibleCategory.allCases) { category in
                        Button {
                            onSelect(category)
                        } label: {
                            categoryRow(category)       // 이 안은 이미 primary/secondary 잘 써놓음
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }
    
    
    @ViewBuilder
    private func categoryRow(_ category: BibleCategory) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(category.rawValue)
                    .font(.headline)
                    .foregroundColor(.black)                    // ✅ 카드 안은 항상 진한 글자
                
                Text(category.subtitle)
                    .font(.caption)
                    .foregroundColor(Color.black.opacity(0.6))  // ✅ 부제는 살짝 연하게
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(Color.black.opacity(0.4))      // ✅ 아이콘도 어두운 회색
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.white)                                // ✅ 카드 배경은 항상 흰색
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
    }
}
