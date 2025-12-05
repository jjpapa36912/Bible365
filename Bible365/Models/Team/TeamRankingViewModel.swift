//
//  TeamRankingViewModel.swift
//  Bible365
//
//  Created by 김동준 on 12/5/25.
//

import Foundation
// TeamProgressEntryDTO.swift

import Foundation

/// 팀 랭킹 1줄을 나타내는 DTO


final class TeamRankingViewModel: ObservableObject {
    @Published var entries: [BibleAPI.TeamProgressEntryDTO] = []
        @Published var myEntry: BibleAPI.TeamProgressEntryDTO?

    private let teamId: Int

    init(teamId: Int) {
        self.teamId = teamId
    }

    @MainActor
    func load() async {
        do {
            let list = try await BibleAPI.shared.fetchTeamRanking(teamId: teamId)
            self.entries = list
            self.myEntry = try? await BibleAPI.shared.fetchMyTeamProgress(teamId: teamId)
        } catch {
            print("팀 랭킹 로딩 실패: \(error)")
        }
    }
}
