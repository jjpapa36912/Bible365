//
//  TeamHistoryView.swift
//  Bible365
//
//  Created by 김동준 on 11/30/25.
//

import Foundation
//
//  TeamHistoryView.swift
//  Bible365
//

import SwiftUI

struct TeamHistoryView: View {

    @Environment(\.dismiss) private var dismiss
    @StateObject private var store = TeamChallengeStore.shared

    var body: some View {
        NavigationStack {
            List {
                ForEach(store.history) { item in
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(item.teamName)
                                .font(.headline)

                            if let completed = item.completedAt {
                                Text("완료일: \(completed.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(item.members) { m in
                                    HStack(alignment: .top, spacing: 6) {
                                        Text(m.nickname)
                                            .font(.subheadline)
                                        Text(
                                            m.books
                                                .map { $0.nameKo }
                                                .joined(separator: ", ")
                                        )
                                        .font(.footnote)
                                        .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("팀 히스토리")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") { dismiss() }
                }
            }
            .task {
                await store.loadHistory()
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
}
