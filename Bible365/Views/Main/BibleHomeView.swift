import SwiftUI

struct BibleHomeView: View {
    // 전체 진행률/랭킹용 저장소 (싱글턴)
    @StateObject private var progressStore = ReadingProgressStore.shared

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                headerSection
                globalProgressSection
                currentBookProgressSection

                NavigationLink {
                    // 네가 이미 만든 개인 챌린지 읽기 화면
                    PersonalChallengeReadingView(mode: .personal)
                } label: {
                    startChallengeButton
                }

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 32)
        }
    }

    // MARK: - 서브뷰 쪼개기 (타입 체크 에러 방지 포인트)

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Bible 365")
                .font(.largeTitle)
                .bold()

            Text("오늘도 말씀 한 절씩, 차곡차곡 쌓아가요.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// 성경 66권 전체 기준 진행률
    /// 성경 66권 전체 기준 진행률
    private var globalProgressSection: some View {
        let globalRatio = progressStore.globalProgress(mode: .personal)
        let globalPercent = Int(globalRatio * 100)

        return VStack(alignment: .leading, spacing: 8) {
            Text("성경 전체 진행률")
                .font(.headline)

            ProgressView(value: globalRatio)
                .frame(maxWidth: .infinity)

            Text("\(globalPercent)% 완료")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    /// “현재 집중 책” 진행률
    private var currentBookProgressSection: some View {
        let proRatio = progressStore.progressForBook(bookCode: "PRO", mode: .personal)
        let proPercent = Int(proRatio * 100)

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("현재 책 진행률")
                    .font(.headline)
                Spacer()
                Text("잠언")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            ProgressView(value: proRatio)
                .frame(maxWidth: .infinity)

            Text("\(proPercent)% 완료")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }


    private var startChallengeButton: some View {
        Text("개인 챌린지 시작하기")
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.blue)
            .cornerRadius(16)
    }
}
