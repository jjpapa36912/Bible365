//
//  RankingBoardView.swift
//  Bible365
//
//  Created by 김동준 on 11/29/25.
//

import Foundation
import SwiftUI

struct RankingEntry: Identifiable, Codable {
    let id: Int64          // 서버에서 Long 이면 Int64 가 편함
    let nickname: String
    let completionCount: Int
    let progress: Double

    enum CodingKeys: String, CodingKey {
        case id
        case nickname
        case completionCount
        case progress
    }
}


struct RankingBoardView: View {
    let entries: [RankingEntry]
    let currentUserId: Int64
    @Environment(\.dismiss) private var dismiss   // 🔹 추가

    private var sortedEntries: [RankingEntry] {
        entries.sorted { lhs, rhs in
            if lhs.completionCount != rhs.completionCount {
                return lhs.completionCount > rhs.completionCount
            } else {
                return lhs.progress > rhs.progress
            }
        }
    }

    private var myRank: Int? {
        sortedEntries.firstIndex(where: { $0.id == currentUserId })
            .map { $0 + 1 }
    }

        var body: some View {
            ZStack {
                LinearGradient(
                    colors: [
                        Color.blue,
                        Color.blue.opacity(0.85)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 16) {
                    header

                    ScrollView {
                        VStack(spacing: 10) {
                            ForEach(Array(sortedEntries.enumerated()), id: \.element.id) { index, entry in
                                RankingRow(
                                    rank: index + 1,
                                    entry: entry,
                                    isMe: entry.id == currentUserId
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                    }
                }
                .padding(.top, 20)
            }
        }

    private var header: some View {
            VStack(spacing: 8) {
                HStack {
                    // 🔹 홈 버튼
                    Button {
                        dismiss()   // 네비게이션 스택에서 한 단계 뒤로 (메인 화면)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "house.fill")
                            Text("홈")
                        }
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(14)
                    }

                    Spacer()

                    Text("랭킹 보드")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 16)

                if let myRank {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("나의 순위")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                            Text("#\(myRank)위")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
}

struct RankingRow: View {
    let rank: Int
    let entry: RankingEntry
    let isMe: Bool

    var body: some View {
        HStack(spacing: 12) {
            Text("#\(rank)")
                .font(.headline)
                .foregroundColor(.white)

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.nickname)
                    .fontWeight(isMe ? .bold : .regular)
                    .foregroundColor(.white)

                HStack(spacing: 8) {
                    Text("완독 \(entry.completionCount)회")
                    Text("진행 \(Int(entry.progress * 100))%")
                }
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(isMe ? Color.white.opacity(0.25) : Color.white.opacity(0.10))
        )
    }
}
