//
//  TeamChallengeHomeView.swift
//  Bible365
//
//  Created by 김동준 on 11/30/25.
//

import Foundation
import SwiftUI

struct TeamChallengeHomeView: View {

    @StateObject private var store = TeamChallengeStore.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let activeTeam = store.activeTeam {
                ActiveTeamDashboardView(team: activeTeam)
            } else {
                TeamCreateView {_ in 
                    // 필요하면 만든 직후 리로드
                    Task { await store.loadActiveTeam() }
                }
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .navigationTitle("팀 챌린지")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await store.loadActiveTeam()
        }
        .sheet(item: $store.recentlyCompletedTeam) { (historyEntry: TeamHistoryItem) in
            TeamCompletionView(historyEntry: historyEntry)
        }
    }
}

