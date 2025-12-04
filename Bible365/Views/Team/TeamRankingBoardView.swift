//
//  TeamRankingBoardView.swift
//  Bible365
//
//  Created by 김동준 on 11/30/25.
//

//
//  TeamRankingBoardView.swift
//  Bible365
//

import SwiftUI
import Foundation

struct TeamRankingBoardView: View {

    @StateObject private var store = TeamChallengeStore.shared
    @Environment(\.dismiss) private var dismiss

    /// 리스트에서 탭한 히스토리 (상세 sheet 용)
    @State private var selectedHistory: TeamHistoryItem? = nil

    var body: some View {
        NavigationStack {
            List {
                ForEach(sortedHistory) { entry in
                    Button {
                        selectedHistory = entry
                    } label: {
                        HStack(alignment: .top, spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(entry.teamName)
                                    .font(.headline)

                                HStack(spacing: 4) {
                                    Text("팀원 \(entry.members.count)명")

                                    if let completed = entry.completedAt {
                                        Text("• \(completed.formatted(date: .abbreviated, time: .omitted)) 완료")
                                    }
                                }
                                .font(.footnote)
                                .foregroundColor(.secondary)

                            }

                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("팀 랭킹 보드")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") { dismiss() }
                }
            }
            .task {
                await store.loadHistory()
            }
            .sheet(item: $selectedHistory) { entry in
                TeamCompletionView(historyEntry: entry)
            }
        }
    }

    /// 완료일 최신순 정렬
    private var sortedHistory: [TeamHistoryItem] {
        store.history.sorted { lhs, rhs in
            switch (lhs.completedAt, rhs.completedAt) {
            case let (l?, r?): return l > r      // 둘 다 있으면 최신순
            case (_?, nil):    return true       // 왼쪽만 있으면 왼쪽이 앞으로
            case (nil, _?):    return false
            default:           return lhs.id > rhs.id
            }
        }
    }
}

// 히스토리 상세: 누가 어떤 책 맡았는지
struct TeamHistoryDetailView: View {

    let entry: TeamHistoryEntry
    @Environment(\.dismiss) private var dismiss

    // 책 index -> 담당 멤버
    private var assignmentMap: [Int: TeamMember] {
        var map: [Int: TeamMember] = [:]
        for a in entry.assignments {
            for idx in a.bookIndices {
                map[idx] = a.member
            }
        }
        return map
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {

                    Text(entry.teamName)
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("완료일: \(formatted(date: entry.completedAt))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Divider()

                    Text("팀원")
                        .font(.headline)

                    ForEach(entry.members) { m in
                        Text("• \(m.name)")
                    }

                    Divider()

                    Text("책 배정")
                        .font(.headline)

                    ForEach(entry.members) { member in
                        let books = BibleBooks.all.enumerated().compactMap { (index, book) -> BibleBook? in
                            assignmentMap[index] == member ? book : nil
                        }

                        if !books.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(member.name)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                Text(books.map { $0.nameKo }.joined(separator: ", "))
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }

                }
                .padding()
            }
            .navigationTitle("팀 히스토리")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") { dismiss() }
                }
            }
        }
    }

    private func formatted(date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy.MM.dd"
        return f.string(from: date)
    }
}

