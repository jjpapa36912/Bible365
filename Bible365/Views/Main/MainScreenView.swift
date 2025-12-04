//
//  MainScreenView.swift
//  Bible365
//
//  Created by 김동준 on 11/22/25.
//

import Foundation
import SwiftUI

struct MainScreenView: View {
    var onLogout: (() -> Void)? = nil   // RootView 에서 주는 콜백

    // 🔹 진행도 스토어 (개인 챌린지 기반)
    @ObservedObject private var progressStore = ReadingProgressStore.shared
    private var currentNickname: String {
        UserDefaults.standard.string(forKey: "nickname") ?? ""
    }

    // 🔹 서버 랭킹용
    @StateObject private var rankingVM = RankingViewModel()
    // 🔹 내 랭킹 엔트리 (서버 기준)
    private var myRankingEntry: RankingEntry? {
        guard let myId = rankingVM.currentUserId else { return nil }
        return rankingVM.entries.first(where: { $0.id == myId })
    }

    // 🔹 완독/진행률: 우선 서버 값, 없으면 로컬 값
    private var myCompletionCount: Int {
        if let entry = myRankingEntry {
            return entry.completionCount
        }
        return progressStore.globalCompletionCount()
    }

    private var myProgress: Double {
        if let entry = myRankingEntry {
            return entry.progress   // 0.0 ~ 1.0 이라고 가정
        }
        return progressStore.globalProgress()
    }

    private var myReadPercent: Int {
        Int(myProgress * 100)
    }
//    // 🔹 내 완독/진행률
//    private var myCompletionCount: Int {
//        progressStore.globalCompletionCount()
//    }
//
//    private var myProgress: Double {
//        progressStore.globalProgress()           // 0.0 ~ 1.0
//    }
//
//    private var myReadPercent: Int {
//        Int(myProgress * 100)
//    }

    // 🔹 서버에서 내려온 엔트리를 그대로 사용
    private var rankingEntries: [RankingEntry] {
        rankingVM.entries
    }
    

    var body: some View {
        ZStack(alignment: .top) {
            // 뒷배경 (라이트/다크 자동 대응)
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            // 🔹 1) 스크롤 뷰
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 32) {

                    // 상단 카드 (헤더 높이만큼 여유를 둠)
                    BibleReadingCard(
                        completionCount: myCompletionCount,
                        readPercent: myReadPercent
                    )
                    .padding(.top, 140)

                    // 🔹 랭킹 보드 섹션 (항상 섹션은 보이게)
                    rankingSection

                    // 팀 챌린지
                    VStack(alignment: .leading, spacing: 12) {
                        Text("팀 챌린지")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)

                        NavigationLink {
                            TeamChallengeMainView()
                        } label: {
                            ChallengeRowLabel(
                                leftTitle: "시작하기",
                                buttonTitle: "시작"
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    // 개인 챌린지
                    VStack(alignment: .leading, spacing: 12) {
                        Text("개인 챌린지")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)

                        NavigationLink {
                            PersonalChallengeReadingView(mode: .personal)
                        } label: {
                            ChallengeRowLabel(
                                leftTitle: "시작하기",
                                buttonTitle: "시작"
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    // 토론 참여
                    VStack(alignment: .leading, spacing: 12) {
                        Text("토론에 참여하기")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)

                        // TODO: 토론방 / 커뮤니티 화면 연결
                    }

                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 24)
            }

            // 🔹 2) 헤더(파란 영역 + 로그아웃 버튼)
            headerView
        }
        // 🔹 화면 들어올 때 한 번 랭킹 불러오기
        .task {
            await rankingVM.load()
        }
    }

    // MARK: - 랭킹 섹션

    @ViewBuilder
    private var rankingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("랭킹 보드")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.primary)

            if rankingEntries.isEmpty {
                // 🔹 서버에서 아직 아무도 없거나, 로딩 실패 등
                Text("아직 랭킹 데이터가 없습니다.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            } else {
                // 🔹 현재 로그인 유저의 랭킹 계산
                let myId = rankingVM.currentUserId
                let myIndex = myId.flatMap { id in
                    rankingEntries.firstIndex(where: { $0.id == id })
                }

                if let myIndex {
                    let myRank = myIndex + 1

                    NavigationLink {
                        RankingBoardView(
                            entries: rankingEntries,
                            currentUserId: rankingVM.currentUserId ?? 0
                        )
                    } label: {
                        RankingPreviewCard(
                            myRank: myRank,
                            totalCount: rankingEntries.count,
                            completionCount: myCompletionCount,
                            readPercent: myReadPercent
                        )
                    }
                    .buttonStyle(.plain)
                } else {
                    // 🔹 내 랭킹을 못 찾은 경우: 전체 랭킹 보기 카드만 노출
                    NavigationLink {
                        RankingBoardView(
                            entries: rankingEntries,
                            currentUserId: rankingVM.currentUserId ?? 0
                        )
                    } label: {
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("랭킹 보기")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text("전체 \(rankingEntries.count)명의 진행 상황을 확인하세요")
                                    .font(.footnote)
                                    .foregroundColor(.primary)
                                    .lineLimit(2)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 18)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(24)
                        .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 4)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - 헤더 뷰

    private var headerView: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 40, style: .continuous)
                .fill(Color.blue)
                .frame(height: 220)
                .ignoresSafeArea(edges: .top)

            VStack(spacing: 0) {
                HStack {
                    // 로그아웃 버튼
                    Button(action: {
                        print("🔵 Logout tapped")
                        onLogout?()
                    }) {
                        Text("로그아웃")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(12)
                    }

                    Spacer()

                    // 🔹 현재 사용자 닉네임 표시
                    Text("\(currentNickname) 님")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.trailing, 8)

                    // 설정 버튼
                    Button(action: {
                        // TODO
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                Spacer()
            }
        }
        .frame(height: 220)
        .frame(maxWidth: .infinity, alignment: .top)
    }

}

// MARK: - 카드 뷰들

struct BibleReadingCard: View {
    let completionCount: Int
    let readPercent: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("성경 읽기")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            HStack {
                VStack {
                    Text("\(completionCount)")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(.primary)
                    Text("완독")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)

                Rectangle()
                    .fill(Color.secondary.opacity(0.2))
                    .frame(width: 1, height: 40)

                VStack {
                    Text("\(readPercent)%")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(.primary)
                    Text("읽음")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
            }

            Button(action: {
                // TODO: 계속 읽기 화면으로 이동
            }) {
                Text("이어 읽기")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(22)
            }
        }
        .padding(24)
        .background(Color(UIColor.secondarySystemBackground)) // ✅ 카드 배경
        .cornerRadius(28)
        .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 8)
    }
}

// 예전 ChallengeRow (지금은 NavigationLink 라벨로만 쓰므로 안 써도 됨)
struct ChallengeRow: View {
    let leftTitle: String
    let buttonTitle: String
    let action: () -> Void

    var body: some View {
        HStack {
            Text(leftTitle)
                .font(.headline)
                .foregroundColor(.primary)

            Spacer()

            Button(action: action) {
                Text(buttonTitle)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(22)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 4)
    }
}

// NavigationLink 에서 사용하는 라벨용 뷰
struct ChallengeRowLabel: View {
    let leftTitle: String
    let buttonTitle: String

    var body: some View {
        HStack {
            Text(leftTitle)
                .font(.headline)
                .foregroundColor(.primary)

            Spacer()

            Text(buttonTitle)
                .fontWeight(.semibold)
                .padding(.horizontal, 28)
                .padding(.vertical, 10)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(22)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 4)
    }
}

// 랭킹 프리뷰 카드
struct RankingPreviewCard: View {
    let myRank: Int
    let totalCount: Int
    let completionCount: Int
    let readPercent: Int

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("내 랭킹")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("#\(myRank) / \(totalCount)명")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }

            Spacer()

            VStack(spacing: 4) {
                Text("\(completionCount)회 완독")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                Text("\(readPercent)% 진행")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }

            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 4)
    }
}
