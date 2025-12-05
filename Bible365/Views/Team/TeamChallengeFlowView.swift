import Foundation
import SwiftUI

enum TeamChallengeFlowStep {
    case createTeam
    case reading
}

struct TeamChallengeFlowView: View {

    @State private var step: TeamChallengeFlowStep = .createTeam

    /// 방금 만든 팀 정보
    @State private var createdTeamId: Int?
    @State private var createdTeamName: String = "우리 팀"

    var body: some View {
        NavigationStack {
            flowContent
        }
        .navigationBarHidden(true)
    }

    // 💡 여기서 뷰 타입을 명확하게 만들어 줌
    @ViewBuilder
    private var flowContent: some View {
        switch step {

        case .createTeam:
            // TeamCreateView(onCreated: (TeamChallengeTeam) -> Void)
            TeamCreateView { team in
                self.createdTeamId = team.id
                self.createdTeamName = team.name
                self.step = .reading
            }

        case .reading:
            if let teamId = createdTeamId {
                // ⚠️ 실제 PersonalChallengeReadingView 초기화 시그니처에 맞게 파라미터 맞춰줘야 함
                PersonalChallengeReadingView(
                    mode: .team(teamId: teamId, name: createdTeamName)
                    // 필요하면 아래처럼 추가 파라미터 넣어
                    // , preselectedBook: nil,
                    //   initialVerseId: nil
                )
            } else {
                Text("팀 정보가 없습니다. 다시 시도해 주세요.")
                    .foregroundColor(.secondary)
            }
        }
    }
}
