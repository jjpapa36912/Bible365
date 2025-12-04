//
//  TeamModel.swift
//  Bible365
//
//  Created by 김동준 on 11/30/25.
//

import Foundation
import SwiftUI
import Combine

// MARK: - /api/team/active 응답 DTO

struct TeamActiveResponseDTO: Codable {
    let id: Int
    let name: String
    let status: String           // "ACTIVE", "COMPLETED" 등
    let startedAt: String        // "2025-11-30T23:11:50.150327"
    let completedAt: String?

    let members: [TeamActiveMemberDTO]
    let assignments: [TeamActiveAssignmentDTO]
    let completedBookIndices: [Int]
}

struct TeamActiveMemberDTO: Codable {
    let userId: Int
    let nickname: String
    let leader: Bool
}

struct TeamActiveAssignmentDTO: Codable {
    let bookIndex: Int
    let bookCode: String?    // 지금은 null로 오지만 필드 존재
    let userId: Int
    let nickname: String
}

// MARK: - 공통으로 쓸 팀/배정 도메인 모델

/// 서버에서 내려주는 “요약 멤버 정보”
struct TeamMemberSummary: Identifiable, Equatable {
    let id: Int          // userId
    let nickname: String
    let isLeader: Bool
}

/// 특정 멤버에게 배정된 한 권
struct AssignedBook: Identifiable, Equatable {
    /// 동일 팀 내에서 bookIndex 는 유니크하다고 가정하고 bookIndex 를 ID 로 사용
    let id: Int
    let bookIndex: Int
    let bookCode: String?
    let member: TeamMemberSummary

    /// 66권 메타에서 찾아온 실제 책 정보
    var book: BibleBook? {
        BibleBooks.book(forIndex: bookIndex)
    }

    static func == (lhs: AssignedBook, rhs: AssignedBook) -> Bool {
        lhs.id == rhs.id
    }
}

/// 현재/과거 팀 정보를 표현하는 공통 모델
struct TeamChallengeTeam: Identifiable {
    let id: Int
    let name: String
    let status: String

    /// 시작/완료 시각 (ISO8601 문자열 → Date 변환)
    let startedAt: Date?
    let completedAt: Date?

    /// 팀에 속한 멤버들
    let members: [TeamMemberSummary]

    /// 66권 배정 정보
    let assignments: [AssignedBook]

    /// 완료된 책 index 집합
    let completedBookIndices: Set<Int>

    /// 내 userId 기준으로 맡은 책들
    func assignments(forUserId userId: Int) -> [AssignedBook] {
        assignments.filter { $0.member.id == userId }
    }

    /// 팀 전체 책 완료 진행률 (완독된 권 수 / 66)
    var progressRatio: Double {
        guard !BibleBooks.all.isEmpty else { return 0 }
        return Double(completedBookIndices.count) / Double(BibleBooks.all.count)
    }
}

// MARK: - 히스토리 모델

struct TeamHistoryItem: Identifiable, Equatable {
    let id: Int
    let teamName: String
    let completedAt: Date?
    let members: [MemberBooks]

    struct MemberBooks: Identifiable, Equatable {
        let id: Int        // userId
        let nickname: String
        let bookIndices: [Int]
        var books: [BibleBook] {
            bookIndices.compactMap { BibleBooks.book(forIndex: $0) }
        }
    }
}

// MARK: - 날짜 파서

fileprivate let teamDateFormatter: ISO8601DateFormatter = {
    let f = ISO8601DateFormatter()
    f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return f
}()

fileprivate func parseDate(_ s: String?) -> Date? {
    guard let s else { return nil }
    // 서버 포맷이 ISO8601 이면 여기서 대부분 파싱됨
    if let d = teamDateFormatter.date(from: s) {
        return d
    }
    // 필요하면 fallback 패턴 추가 (예: "yyyy-MM-dd'T'HH:mm:ss")
    return nil
}

// MARK: - DTO → 도메인 매핑

// 1) /api/team/active 전용 매핑
extension TeamActiveResponseDTO {
    func toModel() -> TeamChallengeTeam {
        // userId → TeamMemberSummary 맵
        let memberMap: [Int: TeamMemberSummary] = Dictionary(
            uniqueKeysWithValues: members.map { m in
                let summary = TeamMemberSummary(
                    id: m.userId,
                    nickname: m.nickname,
                    isLeader: m.leader
                )
                return (m.userId, summary)
            }
        )

        // 배정 정보
        let assigned: [AssignedBook] = assignments.map { a in
            let member = memberMap[a.userId] ?? TeamMemberSummary(
                id: a.userId,
                nickname: a.nickname,
                isLeader: false
            )
            return AssignedBook(
                id: a.bookIndex,
                bookIndex: a.bookIndex,
                bookCode: a.bookCode,
                member: member
            )
        }

        let completedSet = Set(completedBookIndices)

        return TeamChallengeTeam(
            id: id,
            name: name,
            status: status,
            startedAt: parseDate(startedAt),
            completedAt: parseDate(completedAt),
            members: Array(memberMap.values).sorted { $0.id < $1.id },
            assignments: assigned.sorted { $0.bookIndex < $1.bookIndex },
            completedBookIndices: completedSet
        )
    }
}

// 2) 기존 TeamResponseDTO → 공통 모델 매핑
//    (TeamResponseDTO, TeamHistoryDTO 는 다른 파일에 정의되어 있다고 가정)
extension TeamResponseDTO {
    func toModel() -> TeamChallengeTeam {
        // 멤버 맵
        let memberMap: [Int: TeamMemberSummary] = Dictionary(
            uniqueKeysWithValues: members.map { m in
                let summary = TeamMemberSummary(
                    id: m.userId,
                    nickname: m.nickname,
                    isLeader: m.leader
                )
                return (m.userId, summary)
            }
        )

        // 배정
        let assigned: [AssignedBook] = assignments.map { a in
            let member = memberMap[a.userId] ?? TeamMemberSummary(
                id: a.userId,
                nickname: a.nickname,
                isLeader: false
            )
            return AssignedBook(
                id: a.bookIndex,
                bookIndex: a.bookIndex,
                bookCode: a.bookCode,
                member: member
            )
        }

        let completedSet = Set(completedBookIndices ?? [])

        return TeamChallengeTeam(
            id: id,
            name: name,
            status: status,
            startedAt: parseDate(startedAt),
            completedAt: parseDate(completedAt),
            members: Array(memberMap.values).sorted { $0.id < $1.id },
            assignments: assigned.sorted { $0.bookIndex < $1.bookIndex },
            completedBookIndices: completedSet
        )
    }
}

// 3) 히스토리 DTO → 히스토리 모델 매핑
extension TeamHistoryDTO {
    func toModel() -> TeamHistoryItem {
        let memberModels: [TeamHistoryItem.MemberBooks] = memberBooks.map {
            TeamHistoryItem.MemberBooks(
                id: $0.userId,
                nickname: $0.nickname,
                bookIndices: $0.bookIndices.sorted()
            )
        }

        return TeamHistoryItem(
            id: id,
            teamName: teamName,
            completedAt: parseDate(completedAt),
            members: memberModels
        )
    }
}

// MARK: - 로컬에서만 사용하는 “플래닝용” 모델들
// (팀 구성/배정 시에만 사용, 서버 응답과는 별도)

/// 친구(팀원) 한 명 (로컬에서 팀 편성할 때 사용)
struct TeamMember: Identifiable, Hashable, Codable {
    let id: String      // 서버의 userId (문자열)
    let name: String    // 표시용 이름
}

/// 특정 팀원이 맡은 책 구간 (로컬 임시 상태)
struct TeamBookAssignment: Identifiable, Codable {
    let id: UUID = UUID()
    let member: TeamMember
    let bookIndices: [Int]   // BibleBooks.all 의 index 배열 (예: [0,1,2])
}

/// 팀 전체 정보 (로컬 임시 상태)
struct TeamChallenge: Identifiable, Codable {
    let id: UUID
    var name: String
    var members: [TeamMember]
    var assignments: [TeamBookAssignment]   // 66권이 팀원들에게 나뉜 결과
    var startedAt: Date
    var completedAt: Date?                  // 1독 완료 시 세팅

    // 팀 전체에서 완료된 책 index 집합 (서버 기준으로 오면 더 좋음)
    var completedBookIndices: Set<Int>

    // 1독 완료 여부 (66권 모두 완료)
    var isCompleted: Bool {
        completedBookIndices.count >= BibleBooks.all.count
    }
}

/// 완료된 팀 히스토리 (랭킹 보드용, 로컬 저장용)
struct TeamHistoryEntry: Identifiable, Codable {
    let id: UUID
    let teamName: String
    let members: [TeamMember]
    let assignments: [TeamBookAssignment]
    let completedAt: Date
    let totalReadCount: Int   // 1독 기준이면 항상 1, 나중에 여러 번 도전 가능
}
