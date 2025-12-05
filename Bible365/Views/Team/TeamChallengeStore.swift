
//
//  TeamChallengeStore.swift
//  Bible365
//

import Foundation

@MainActor
final class TeamChallengeStore: ObservableObject {

    static let shared = TeamChallengeStore()
    private init() {}

    // ✅ 내가 속한 모든 팀 목록
    @Published var myTeams: [TeamChallengeTeam] = []

    // ✅ 현재 화면에서 주로 보는 팀 (선택된/대표 ACTIVE 팀)
    @Published var activeTeam: TeamChallengeTeam?

    // 최근 완료된 팀 (예: 히스토리 화면에서 강조용)
    @Published var recentlyCompletedTeam: TeamHistoryItem?

    // 친구 리스트 (서버에서 내려온 후보)
    @Published var friends: [TeamFriendDTO] = []

    // 팀 생성 시 선택한 친구 ID (뷰에서 직접 쓰지 않아도 됨)
    @Published var selectedFriendIds: Set<Int> = []

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

    // 친구 선택 / 해제
    func toggleFriend(id: Int) {
        if selectedFriendIds.contains(id) {
            selectedFriendIds.remove(id)
        } else {
            selectedFriendIds.insert(id)
        }
    }

    // MARK: - 2) 내 ACTIVE 팀 불러오기 (기존 단일 팀)

    /// 서버에 "현재 ACTIVE 팀 1개"를 따로 주는 API가 있을 경우 사용
    func loadActiveTeam() async {
        do {
            isLoading = true
            defer { isLoading = false }

            let dto = try await TeamChallengeAPI.shared.fetchActiveTeam()
            if let dto {
                let model = dto.toModel()
                self.activeTeam = model

                // myTeams에도 동기화
                upsertTeam(model)
            } else {
                self.activeTeam = nil
            }
        } catch {
            print("❌ loadActiveTeam error:", error)
            self.errorMessage = "팀 정보를 불러오지 못했어요.\n\(error.localizedDescription)"
        }
    }
    // 🔥 새로 추가 / 정리: 내 팀 전체 로딩
        func reloadMyTeams() async {
            do {
                isLoading = true
                defer { isLoading = false }

                // 서버에서 내가 속한 팀 전체 조회
                let list = try await TeamChallengeAPI.shared.fetchMyTeams()

                let models = list.map { $0.toModel() }
                self.myTeams = models

                // ACTIVE 팀이 있으면 우선 선택, 없으면 첫 번째 팀
                if let active = models.first(where: { $0.status == "ACTIVE" }) {
                    self.activeTeam = active
                } else {
                    self.activeTeam = models.first
                }
            } catch {
                print("❌ reloadMyTeams error:", error)
                self.errorMessage = "내 팀 목록을 불러오지 못했어요.\n\(error.localizedDescription)"
            }
        }
    // MARK: - 2-1) 내가 속한 모든 팀 불러오기 (여러 팀 지원 핵심)

//    func loadMyTeams() async {
//        do {
//            isLoading = true
//            defer { isLoading = false }
//
//            // 🔹 서버에서 "내가 속한 팀 전체"를 내려주는 API라고 가정
//            let list = try await TeamChallengeAPI.shared.fetchMyTeams()
//
//            let models = list.map { $0.toModel() }
//            self.myTeams = models
//
//            // ACTIVE 팀이 있다면 activeTeam으로 선정, 없으면 첫 번째 팀
//            if let active = models.first(where: { $0.status == "ACTIVE" }) {
//                self.activeTeam = active
//            } else {
//                self.activeTeam = models.first
//            }
//        } catch {
//            print("❌ loadMyTeams error:", error)
//            self.errorMessage = "내 팀 목록을 불러오지 못했어요.\n\(error.localizedDescription)"
//        }
//    }

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

            let model = dto.toModel()

            // ✅ 새로 만든 팀을 myTeams에 추가
            upsertTeam(model)

            // ✅ 방금 만든 팀을 activeTeam으로 설정
            self.activeTeam = model

            return true
        } catch {
            print("❌ createTeam error:", error)
            self.errorMessage = "팀 생성에 실패했어요.\n\(error.localizedDescription)"
            return false
        }
    }

    // MARK: - 4) 책 완독 이벤트 (= markBookFinished 서버 호출)

    /// 팀 내에서 어떤 책이 1독 완료되었을 때 호출
    /// - 여러 팀 지원을 위해 teamId를 명시적으로 받도록 변경
    func markBookFinished(teamId: Int, bookIndex: Int) async {
        do {
            isLoading = true
            defer { isLoading = false }

            let dto = try await TeamChallengeAPI.shared.markBookFinished(
                teamId: teamId,
                bookIndex: bookIndex
            )

            let updatedTeam = dto.toModel()

            // ✅ myTeams 안에서 해당 팀 갱신
            upsertTeam(updatedTeam)

            // ✅ activeTeam이 이 팀이면 같이 갱신
            if activeTeam?.id == updatedTeam.id {
                activeTeam = updatedTeam
            }

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

    // MARK: - 내부 헬퍼: 팀 upsert

    /// myTeams에 같은 id의 팀이 있으면 교체, 없으면 append
    private func upsertTeam(_ team: TeamChallengeTeam) {
        if let idx = myTeams.firstIndex(where: { $0.id == team.id }) {
            myTeams[idx] = team
        } else {
            myTeams.append(team)
        }
    }
}
