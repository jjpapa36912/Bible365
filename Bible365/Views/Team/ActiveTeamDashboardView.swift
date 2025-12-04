//
//  ActiveTeamDashboardView.swift
//  Bible365
//
//  Created by 김동준 on 11/30/25.
//

import Foundation
import SwiftUI

// MARK: - 메인 대시보드

struct ActiveTeamDashboardView: View {

    let team: TeamChallengeTeam

    // 어떤 시트를 띄울지 구분용
    @State private var activeSheet: ActiveSheet?

    // 한 화면에서 sheet 를 두 개 이상 쓰면 마지막 것만 적용되니까
    // enum + .sheet(item:) 으로 하나로 합쳐줌
    enum ActiveSheet: Identifiable {
        case board
        case ranking

        var id: Int { hashValue }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 팀 이름 + 요약
            Text(team.name)
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top, 8)

            Text("팀원 \(team.members.count)명 • 목표: 1독")
                .font(.subheadline)
                .foregroundColor(.secondary)

            // 진행률 계산
            let totalBooks = BibleBooks.all.count
            let completed = team.completedBookIndices.count
            let percent = Double(completed) / Double(totalBooks)

            // 진행률 카드
            VStack(alignment: .leading, spacing: 8) {
                Text("전체 진행률")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                ProgressView(value: percent)
                    .tint(.blue)

                Text("\(completed)/\(totalBooks)권 완료")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)

            // 팀 보드 버튼
            Button {
                activeSheet = .board
            } label: {
                Text("팀 보드 보기 (66권)")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(20)
            }

            // 랭킹 / 히스토리 버튼
            Button {
                activeSheet = .ranking
            } label: {
                Text("완료 팀 랭킹 보드")
                    .font(.subheadline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .foregroundColor(.blue)
                    .cornerRadius(18)
                    .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 3)
            }

            Spacer()
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .board:
                TeamBoardView(team: team)
            case .ranking:
                TeamRankingBoardView()
            }
        }
    }
}

// MARK: - 팀 보드 (각 책 배정 상태 보기)
