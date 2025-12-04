//
//  TeamCompletionView.swift
//  Bible365
//
//  Created by 김동준 on 11/30/25.
//

import Foundation
import SwiftUI

struct TeamCompletionView: View {

    /// 1독이 완료된 팀 히스토리 엔트리
    let historyEntry: TeamHistoryItem

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                Text("🎉 1독 완료!")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("팀 \"\(historyEntry.teamName)\"이(가)\n성경 1독을 완료했습니다.")
                    .multilineTextAlignment(.center)
                    .font(.headline)

                if let completedAt = historyEntry.completedAt {
                    Text("완료일: \(completedAt.formatted(date: .abbreviated, time: .omitted))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                // 팀원 + 맡았던 책 정보
                VStack(alignment: .leading, spacing: 8) {
                    Text("팀원")
                        .font(.headline)

                    ForEach(historyEntry.members) { member in
                        VStack(alignment: .leading, spacing: 2) {
                            Text("• \(member.nickname)")
                                .font(.subheadline)

                            // 각 팀원이 담당했던 책 리스트
                            if !member.books.isEmpty {
                                Text(member.books.map { $0.nameKo }.joined(separator: ", "))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
                .padding(.horizontal)

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Text("확인")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(20)
                        .padding(.horizontal, 24)
                }

                Spacer()
            }
            .navigationBarHidden(true)
        }
    }
}
