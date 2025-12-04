//
//  TeamCreateView.swift
//  Bible365
//
//  Created by 김동준 on 11/30/25.
//

import Foundation
import SwiftUI
import Combine

struct TeamCreateView: View {

    @Environment(\.dismiss) private var dismiss
    @StateObject private var store = TeamChallengeStore.shared

    @State private var teamName: String = ""
    @State private var searchText: String = ""
    @State private var selectedIds: Set<Int> = []

    let onCreated: () -> Void

    var body: some View {
        NavigationStack {
            VStack {
                Form {
                    Section(header: Text("팀 이름")) {
                        TextField("예: 2025년 1독 도전팀", text: $teamName)
                    }

                    Section(header: Text("팀원 선택 (최대 66명)")) {
                        TextField("닉네임 검색", text: $searchText)
                            .textInputAutocapitalization(.never)

                        let filtered = filteredFriends
                        if filtered.isEmpty {
                            Text("검색 결과가 없습니다.")
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(filtered) { friend in
                                Button {
                                    toggleSelection(friend.id)
                                } label: {
                                    HStack {
                                        Text(friend.name)
                                        Spacer()
                                        if selectedIds.contains(friend.id) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.blue)
                                        } else {
                                            Image(systemName: "circle")
                                                .foregroundColor(.gray)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    if store.isLoading {
                        Section {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                        }
                    }
                }

                Button {
                    Task {
                        await createTeam()
                    }
                } label: {
                    Text("팀 만들기")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(canCreate ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                        .padding(.horizontal)
                }
                .disabled(!canCreate)

                Spacer(minLength: 12)
            }
            .navigationTitle("새 팀 만들기")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") { dismiss() }
                }
            }
            .task {
                await store.loadFriends()
            }
            .alert("에러", isPresented: Binding(
                get: { store.errorMessage != nil },
                set: { _ in store.clearError() }
            )) {
                Button("확인", role: .cancel) { }
            } message: {
                Text(store.errorMessage ?? "")
            }
        }
    }

    // MARK: - Helpers

    private var filteredFriends: [TeamFriendDTO] {
        if searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            return store.friends
        } else {
            return store.friends.filter {
                $0.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    private var canCreate: Bool {
        !teamName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !selectedIds.isEmpty &&
        selectedIds.count <= 66
    }

    private func toggleSelection(_ id: Int) {
        if selectedIds.contains(id) {
            selectedIds.remove(id)
        } else {
            selectedIds.insert(id)
        }
    }

    private func createTeam() async {
        // ✅ 실제로 서버로 보낼 memberIds
        let memberIds = Array(selectedIds)

        let ok = await store.createTeam(
            teamName: teamName,
            memberIds: memberIds   // ⬅️ 여기 중요!
        )

        if ok {
            onCreated()
            dismiss()
        }
    }
}

// MARK: - 아래 TeamCreateViewModel / FriendRow 는 현재 사용 안 하는 옛 설계라서
// 필요 없으면 과감히 지워도 됨. 남겨두고 싶으면 주석 처리만 해놔도 OK.

final class TeamCreateViewModel: ObservableObject {

    @Published var allFriends: [TeamMember] = []
    @Published var searchText: String = ""
    @Published var selectedMemberIds: Set<String> = []

    @Published var teamName: String = ""

    private var cancellables = Set<AnyCancellable>()
    private let store = TeamChallengeStore.shared

    private var currentUser: TeamMember {
        TeamMember(id: "me", name: "나")
    }

    var filteredFriends: [TeamMember] {
        let keyword = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if keyword.isEmpty {
            return allFriends
        } else {
            return allFriends.filter { $0.name.contains(keyword) }
        }
    }

    var canCreateTeam: Bool {
        !teamName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !selectedMemberIds.isEmpty &&
        selectedMemberIds.count <= 66
    }

    func loadFriends() {
        Task {
            do {
                await store.loadFriends()
            } catch {
                await MainActor.run {
                    self.allFriends = [currentUser]
                    self.selectedMemberIds.insert(currentUser.id)
                }
            }
        }
    }

    func toggleSelection(_ friend: TeamMember) {
        if selectedMemberIds.contains(friend.id) {
            selectedMemberIds.remove(friend.id)
        } else {
            guard selectedMemberIds.count < 66 else { return }
            selectedMemberIds.insert(friend.id)
        }
    }

    func createTeam() async {
        let _ = allFriends.filter { selectedMemberIds.contains($0.id) }
        await store.createTeam(teamName: teamName, memberIds: []) // 사용 안 함
    }
}

struct FriendRow: View {
    let friend: TeamMember
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack {
                Text(friend.name)
                    .foregroundColor(.primary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                } else {
                    Image(systemName: "circle")
                        .foregroundColor(.gray)
                }
            }
        }
    }
}
