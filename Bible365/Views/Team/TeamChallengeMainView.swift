//
//  TeamChallengeMainView.swift
//  Bible365
//
//  Created by 김동준 on 11/30/25.
//

import Foundation
import SwiftUI

// MARK: - 1) 메인 팀 챌린지 화면

struct TeamChallengeMainView: View {

    @StateObject private var store = TeamChallengeStore.shared
    @State private var showCreateTeamSheet = false

    var body: some View {
        NavigationStack {
            List {
                // ✅ 1) 내가 참여 중인 모든 팀
                Section(header: Text("내가 참여 중인 팀")) {
                    if store.myTeams.isEmpty {
                        noTeamSection
                    } else {
                        ForEach(store.myTeams) { team in
                            NavigationLink(
                                destination: TeamDetailView(team: team)
                            ) {
                                TeamRow(team: team)
                            }
                        }
                    }
                }

                // ✅ 2) 완료된 팀 랭킹
                Section {
                    NavigationLink(
                        destination: TeamRankingBoardView()
                    ) {
                        Text("완료된 팀 랭킹 보드")
                    }
                }
            }
            .navigationTitle("팀 챌린지")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showCreateTeamSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        // 🔹 화면 진입 시 내 팀 목록 로딩
        .onAppear {
            Task {
                await store.reloadMyTeams()
            }
        }
        // 🔹 새 팀 생성 후 다시 로딩
        .sheet(isPresented: $showCreateTeamSheet) {
            TeamCreateView { _ in
                Task {
                    await store.reloadMyTeams()
                }
            }
        }
    }

    // 그대로 사용하던 noTeamSection
    private var noTeamSection: some View {
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


// MARK: - 2) 팀 리스트 Row

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


// MARK: - 3) 팀 상세 화면

struct TeamDetailView: View {

    let team: TeamChallengeTeam

       @StateObject private var boardVM = TeamBoardViewModel()

       var body: some View {
           ScrollView {
               VStack(alignment: .leading, spacing: 20) {

                   teamHeader
                   membersSection
                   myAssignmentsSection

                   // 🔹 여기: 팀 보드 섹션 추가
                   teamBoardSection

                   Spacer(minLength: 20)
               }
               .padding(.top, 16)
           }
           .navigationTitle(team.name)
           .navigationBarTitleDisplayMode(.inline)
           .task {
               await boardVM.loadBoard(teamId: team.id)
           }
       }

       private var teamBoardSection: some View {
           VStack(alignment: .leading, spacing: 8) {
               Text("이 팀 진행 보드")
                   .font(.headline)
                   .padding(.horizontal, 20)

               if boardVM.isLoading {
                   ProgressView()
                       .padding(.horizontal, 20)
               } else if let error = boardVM.errorMessage {
                   Text(error)
                       .font(.caption)
                       .foregroundColor(.red)
                       .padding(.horizontal, 20)
               } else {
                   // 내 순위/진행
                   if let me = boardVM.myEntry {
                       HStack {
                           Text("내 진행도: \(Int(me.progress * 100))% / \(me.completionCount)독")
                               .font(.subheadline)
                           Spacer()
                       }
                       .padding(.horizontal, 20)
                   }

                   // 팀원별 랭킹 리스트
                   ForEach(boardVM.ranking, id: \.userId) { entry in
                       HStack {
                           Text(entry.nickname)
                           Spacer()
                           Text("\(Int(entry.progress * 100))%")
                           Text("\(entry.completionCount)독")
                               .foregroundColor(.secondary)
                       }
                       .font(.caption)
                       .padding(.horizontal, 20)
                       .padding(.vertical, 4)
                   }
               }
           }
       }

    // MARK: - 팀 헤더
    // TeamDetailView 안에 추가 예시 (단순 표시용)

    private var myTeamBoardPreview: some View {
        let mode: BibleProgressMode = .team(teamId: team.id, name: team.name)
        let global = ReadingProgressStore.shared.globalProgress(mode: mode)

        return VStack(alignment: .leading, spacing: 8) {
            Text("이 팀에서의 나의 진행률")
                .font(.headline)

            HStack {
                ProgressView(value: global)
                    .frame(maxWidth: .infinity)
                Text("\(Int(global * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

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

    // MARK: - 내가 맡은 성경책 → 읽기 플로우

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

                    NavigationLink {
                        // 🔥 팀마다 완전히 다른 진행도/보드가 되도록 teamId까지 넣어줌
                        PersonalChallengeReadingView(
                            mode: .team(teamId: team.id, name: team.name),
                            preselectedBook: book,
                            initialVerseId: nil
                        )
                    }
                        label: {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(book.nameKo)
                                Spacer()
                                Text("(\(book.code))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Text("팀 진행률은 곧 제공될 예정입니다.")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 6)
                    }
                }
            }
        }
    }
}

