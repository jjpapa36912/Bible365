//
//  TeamChallengeFlowView.swift
//  Bible365
//
//  Created by 김동준 on 11/30/25.
//

import Foundation
import SwiftUI

enum TeamChallengeFlowStep {
    case createTeam
    case reading
}

struct TeamChallengeFlowView: View {

    @State private var step: TeamChallengeFlowStep = .createTeam
    @State private var teamName: String = "우리 팀"

    var body: some View {
        NavigationStack {
            switch step {
            case .createTeam:
                TeamCreateView {
                    teamName = "우리 팀"   // 나중에 실제 이름 넣기
                    step = .reading
                }

            case .reading:
                PersonalChallengeReadingView(mode: .team(name: teamName))
            }
        }
        .navigationBarHidden(true)   // ✅ 이 위치
    }
}
