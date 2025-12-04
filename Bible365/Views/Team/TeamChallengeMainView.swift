//
//  TeamChallengeMainView.swift
//  Bible365
//
//  Created by 김동준 on 11/30/25.
//

import Foundation
import SwiftUI

struct TeamChallengeMainView: View {

    @StateObject private var store = TeamChallengeStore.shared
    // 🔹 책별 진행률 계산용
    @StateObject private var progressVM = PersonalChallengeViewModel()

    @State private var showCreateTeamSheet = false

    var body: some View {
        NavigationStack {
            List {
                // ✅ 1) 내 팀 목록 (지금은 activeTeam 1개지만 나중에 확장 가능)
                Section(header: Text("내가 참여 중인 팀")) {
                    if let team = store.activeTeam {
                        NavigationLink {
                            // 🔹 진행률 VM 함께 전달
                            TeamDetailView(team: team, progressVM: progressVM)
                        } label: {
                            TeamRow(team: team)
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("참여 중인 팀이 없습니다.")
                                .foregroundColor(.secondary)

                            Button {
                                showCreateTeamSheet = true
                            } label: {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("새 팀 만들기")
                                }
                            }
                        }
                    }
                }

                // ✅ 2) 완료된 팀 랭킹 / 히스토리로 가는 네비
                Section {
                    NavigationLink {
                        TeamRankingBoardView()
                    } label: {
                        Text("완료된 팀 랭킹 보드")
                    }
                }
            }
            .navigationTitle("팀 챌린지")
            .toolbar {
                // 우측 상단 + 버튼 → 팀 추가
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showCreateTeamSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .task {
            await store.loadActiveTeam()
        }
        .sheet(isPresented: $showCreateTeamSheet) {
            TeamCreateView(onCreated: {
                // 팀 생성 후 목록 갱신
                Task { await store.loadActiveTeam() }
            })
        }
    }
}

// MARK: - 팀 목록 셀

struct TeamRow: View {
    let team: TeamChallengeTeam

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(team.name)
                .font(.headline)

            HStack(spacing: 8) {
                Text("전체 진행률")
                    .font(.caption)
                    .foregroundColor(.secondary)

                ProgressView(value: team.progressRatio)
                    .frame(maxWidth: .infinity)

                Text("\(Int(team.progressRatio * 100))%")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 6)
    }
}

// MARK: - 팀 상세 화면

struct TeamDetailView: View {

    let team: TeamChallengeTeam
    @ObservedObject var progressVM: PersonalChallengeViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                teamHeader

                membersSection

                myAssignmentsSection

                Spacer(minLength: 20)
            }
            .padding(.top, 16)
        }
        .navigationTitle("팀 챌린지")
        .navigationBarTitleDisplayMode(.inline)
        // ⬇️⬇️ 팀이 완료 상태라면 로컬 진행률 리셋
                .onAppear {
                    if team.status == "COMPLETED" {
                        progressVM.forceResetAllProgressForNewRoundFromTeam()
                    }
                }
    }

    // MARK: - 팀 정보 카드

    private var teamHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(team.name)
                .font(.title2)
                .fontWeight(.bold)

            Text("진행 상태: \(team.status)")
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack(spacing: 8) {
                Text("전체 진행률")
                    .font(.caption)
                    .foregroundColor(.secondary)

                ProgressView(value: team.progressRatio)
                    .frame(maxWidth: .infinity)

                Text("\(Int(team.progressRatio * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal, 20)
    }

    // MARK: - 팀원 섹션

    private var membersSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("팀원")
                .font(.headline)
                .padding(.horizontal, 20)

            ForEach(team.members) { member in
                HStack {
                    Text(member.nickname)
                    if member.isLeader {
                        Text("리더")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.yellow.opacity(0.3))
                            .cornerRadius(6)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 4)
            }
        }
    }

    // MARK: - 내가 맡은 성경책 섹션 (책 선택 → 말씀 읽기 + 진행률)

    private var myAssignmentsSection: some View {
        let myUserId = Int(AuthAPI.shared.currentLoginUserId ?? "") ?? -1
        let myAssignments = team.assignments(forUserId: myUserId)
        let myBooks = myAssignments.compactMap { $0.book }

        return VStack(alignment: .leading, spacing: 8) {
            Text("내가 맡은 성경책")
                .font(.headline)
                .padding(.horizontal, 20)

            if myBooks.isEmpty {
                Text("아직 배정된 성경책이 없습니다.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 20)
            } else {
                ForEach(myBooks, id: \.id) { book in
                    // 🔹 이 책에 대한 개인 진행률 (0.0 ~ 1.0)
                    let progress = progressVM.progressForBook(book.code)
                    let percent = Int(progress * 100)

                    NavigationLink {
                        // 팀 모드 + 선택한 책으로 읽기 플로우 진입
                        PersonalChallengeReadingView(
                            mode: .team(name: team.name),
                            preselectedBook: book
                        )
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(book.nameKo)
                                Spacer()
                                Text("(\(book.code))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            HStack(spacing: 8) {
                                ProgressView(value: progress)
                                    .frame(maxWidth: .infinity)
                                Text("\(percent)%")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 6)
                    }
                }
            }
        }
    }
}
