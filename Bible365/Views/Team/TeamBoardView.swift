//
//  TeamBoardView.swift
//  Bible365
//
//  Created by 김동준 on 11/30/25.
//

import Foundation
import SwiftUI

struct TeamBoardView: View {

    let team: TeamChallengeTeam
    @Environment(\.dismiss) private var dismiss

    // 책 index -> 담당 멤버
    private var assignmentMap: [Int: TeamMemberSummary] {
        var map: [Int: TeamMemberSummary] = [:]
        for a in team.assignments {
            map[a.bookIndex] = a.member
        }
        return map
    }



    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                    ForEach(Array(BibleBooks.all.enumerated()), id: \.0) { (index, book) in
                        let isDone = team.completedBookIndices.contains(index)
                        let member = assignmentMap[index]

                        TeamBookCell(book: book,
                                     member: member,
                                     isDone: isDone)
                    }
                }
                .padding()
            }
            .navigationTitle("팀 보드")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") { dismiss() }
                }
            }
        }
    }
}

import SwiftUI

struct TeamBookCell: View {
    let book: BibleBook
    let member: TeamMemberSummary?
    let isDone: Bool

    // MARK: - Style helpers

    private var fillColor: Color {
        isDone ? Color.yellow.opacity(0.9) : Color.white
    }

    private var strokeColor: Color {
        isDone ? Color.orange : Color.gray.opacity(0.2)
    }

    private var shadowColor: Color {
        isDone ? Color.orange.opacity(0.3) : Color.black.opacity(0.02)
    }

    private var shadowRadius: CGFloat {
        isDone ? 6 : 3
    }

    private var shadowY: CGFloat {
        isDone ? 4 : 2
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 4) {
            Text(book.nameKo)
                .font(.caption2)
                .fontWeight(.semibold)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            if let member {
                Text(member.nickname)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            } else {
                Text("미배정")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(6)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(fillColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(strokeColor, lineWidth: 1)
        )
        .shadow(
            color: shadowColor,
            radius: shadowRadius,
            x: 0,
            y: shadowY
        )
    }
}
