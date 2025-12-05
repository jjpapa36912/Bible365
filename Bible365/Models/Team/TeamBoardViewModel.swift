//
//  TeamBoardViewModel.swift
//  Bible365
//
//  Created by 김동준 on 12/6/25.
//

import Foundation
@MainActor
final class TeamBoardViewModel: ObservableObject {

    @Published var isLoading: Bool = false
    @Published var ranking: [BibleAPI.TeamProgressEntryDTO] = []
    @Published var myEntry: BibleAPI.TeamProgressEntryDTO?

    @Published var errorMessage: String?

    func loadBoard(teamId: Int) async {
        do {
            isLoading = true
            defer { isLoading = false }

            // 1) 전체 팀 랭킹 불러오기
            let all = try await BibleAPI.shared.fetchTeamRanking(teamId: teamId)
            self.ranking = all

            // 2) 내 랭킹 엔트리
            self.myEntry = try await BibleAPI.shared.fetchMyTeamProgress(teamId: teamId)

        } catch {
            print("❌ loadBoard error:", error)
            self.errorMessage = "팀 보드를 불러오지 못했어요.\n\(error.localizedDescription)"
        }
    }

    /// 로컬 진행도 → 서버 동기화
    func syncMyProgressToServer(teamId: Int,
                                completionCount: Int,
                                progress: Double) async {
        do {
            isLoading = true
            defer { isLoading = false }

            try await BibleAPI.shared.updateTeamProgress(
                teamId: teamId,
                completionCount: completionCount,
                progress: progress
            )

            // 동기화 후 다시 보드 리로드
            await loadBoard(teamId: teamId)

        } catch {
            print("❌ syncMyProgressToServer error:", error)
            self.errorMessage = "팀 진행도 동기화에 실패했어요.\n\(error.localizedDescription)"
        }
    }
}
