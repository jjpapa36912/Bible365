
//
//  TeamChallengeStore.swift
//  Bible365
//

import Foundation

@MainActor
final class TeamChallengeStore: ObservableObject {

    static let shared = TeamChallengeStore()
    private init() {}

    @Published var recentlyCompletedTeam: TeamHistoryItem?

    // 친구 리스트 (서버에서 내려온 후보)
    @Published var friends: [TeamFriendDTO] = []

    // 팀 생성 시 선택한 친구 ID (뷰에서 직접 쓰지 않아도 됨)
    @Published var selectedFriendIds: Set<Int> = []

    // 현재 내가 참여 중인 팀 (ACTIVE 팀)
    @Published var activeTeam: TeamChallengeTeam?

    // 완료된 팀 히스토리
    @Published var history: [TeamHistoryItem] = []

    // 로딩 / 에러 상태
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // MARK: - 공통 에러 클리어
    func clearError() {
        errorMessage = nil
    }

    // MARK: - 1) 친구 목록 가져오기

    func loadFriends() async {
        do {
            isLoading = true
            defer { isLoading = false }

            let list = try await TeamChallengeAPI.shared.fetchFriends()
            self.friends = list
        } catch {
            print("❌ loadFriends error:", error)
            self.errorMessage = "친구 목록을 불러오지 못했어요.\n\(error.localizedDescription)"
        }
    }

    // 친구 선택 / 해제 (다른 화면에서 쓸 수 있도록 남겨둠)
    func toggleFriend(id: Int) {
        if selectedFriendIds.contains(id) {
            selectedFriendIds.remove(id)
        } else {
            selectedFriendIds.insert(id)
        }
    }

    // MARK: - 2) 내 ACTIVE 팀 불러오기

    func loadActiveTeam() async {
        do {
            isLoading = true
            defer { isLoading = false }

            let dto = try await TeamChallengeAPI.shared.fetchActiveTeam()
            if let dto {
                self.activeTeam = dto.toModel()
            } else {
                self.activeTeam = nil
            }
        } catch {
            print("❌ loadActiveTeam error:", error)
            self.errorMessage = "팀 정보를 불러오지 못했어요.\n\(error.localizedDescription)"
        }
    }

    // MARK: - 3) 팀 생성

    /// 선택된 친구들 ID를 받아 팀 생성
    func createTeam(teamName: String, memberIds: [Int]) async -> Bool {
        // 로컬에서 한 번 더 방어
        guard !memberIds.isEmpty else {
            self.errorMessage = "팀원은 최소 1명 이상 선택해야 해요."
            return false
        }

        do {
            isLoading = true
            defer { isLoading = false }

            let dto = try await TeamChallengeAPI.shared.createTeam(
                teamName: teamName,
                memberIds: memberIds
            )

            self.activeTeam = dto.toModel()
            return true
        } catch {
            print("❌ createTeam error:", error)
            self.errorMessage = "팀 생성에 실패했어요.\n\(error.localizedDescription)"
            return false
        }
    }

    // MARK: - 4) 책 완독 이벤트 (= markBookFinished 서버 호출)

    /// 팀 내에서 어떤 책이 1독 완료되었을 때 호출
    func markBookFinished(bookIndex: Int) async {
        guard let team = activeTeam else { return }

        do {
            isLoading = true
            defer { isLoading = false }

            let dto = try await TeamChallengeAPI.shared.markBookFinished(
                teamId: team.id,
                bookIndex: bookIndex
            )

            self.activeTeam = dto.toModel()
        } catch {
            print("❌ markBookFinished error:", error)
            self.errorMessage = "완독 처리에 실패했어요.\n\(error.localizedDescription)"
        }
    }

    // MARK: - 5) 완료된 팀 히스토리 / 랭킹

    func loadHistory() async {
        do {
            isLoading = true
            defer { isLoading = false }

            let list = try await TeamChallengeAPI.shared.fetchHistory()
            self.history = list.map { $0.toModel() }
        } catch {
            print("❌ loadHistory error:", error)
            self.errorMessage = "히스토리를 불러오지 못했어요.\n\(error.localizedDescription)"
        }
    }
}
