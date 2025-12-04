//
//  BibleProgressBoardView.swift
//  Bible365
//
//  Created by 김동준 on 11/29/25.
//

import Foundation
import SwiftUI
//
//struct BibleProgressBoardView: View {
//
//    let mode: BibleProgressMode
//    let books: [BibleBookProgress]          // 66개
//    let currentBookCode: String?            // 지금 읽는 책 (있으면 하이라이트)
//    var onTapBook: ((BibleBookProgress) -> Void)? = nil
//
//    private var overallProgress: Double {
//        guard !books.isEmpty else { return 0 }
//        let sum = books.reduce(0) { $0 + $1.progress }
//        return sum / Double(books.count)
//    }
//
//    var body: some View {
//        VStack(spacing: 16) {
//            header
//
//            GeometryReader { geo in
//                HStack(spacing: 12) {
//                    ForEach(0..<BibleBoardLayout.columns.count, id: \.self) { columnIndex in
//                        let indices = BibleBoardLayout.columns[columnIndex]
//                        let columnBooks = indices.compactMap { idx in
//                            books.first(where: { $0.book.id == idx })
//                        }
//
//                        VStack(spacing: 6) {
//                            Text(letter(for: columnIndex))
//                                .font(.system(size: 32, weight: .heavy))
//                                .foregroundColor(Color.white.opacity(0.18))
//                                .padding(.bottom, 4)
//
//                            ForEach(columnBooks) { bp in
//                                Button {
//                                    onTapBook?(bp)
//                                } label: {
//                                    BibleBookBlockView(
//                                        progress: bp,
//                                        isCurrent: bp.book.code == currentBookCode,
//                                        mode: mode
//                                    )
//                                }
//                                .buttonStyle(.plain)
//                            }
//
//                            Spacer(minLength: 0)
//                        }
//                        .frame(width: geo.size.width / 5.4)  // 5열 균등
//                    }
//                }
//            }
//            .frame(height: 280)
//
//            footer
//        }
//        .padding(.horizontal, 20)
//        .padding(.vertical, 16)
//        .background(
//            LinearGradient(
//                colors: [Color.blue.opacity(0.95),
//                         Color.blue.opacity(0.8)],
//                startPoint: .topLeading,
//                endPoint: .bottomTrailing
//            )
//            .ignoresSafeArea()
//        )
//        .cornerRadius(32)
//        .shadow(color: Color.black.opacity(0.25), radius: 20, x: 0, y: 12)
//    }
//
//    // MARK: - Header / Footer
//
//    private var header: some View {
//        HStack {
//            VStack(alignment: .leading, spacing: 4) {
//                Text(titleText)
//                    .font(.headline)
//                    .foregroundColor(.white)
//
//                Text(subtitleText)
//                    .font(.caption)
//                    .foregroundColor(.white.opacity(0.8))
//            }
//
//            Spacer()
//
//            VStack(alignment: .trailing, spacing: 4) {
//                Text("\(Int(overallProgress * 100))%")
//                    .font(.system(size: 28, weight: .bold))
//                    .foregroundColor(.white)
//
//                Text("전체 진행률")
//                    .font(.caption2)
//                    .foregroundColor(.white.opacity(0.8))
//            }
//        }
//    }
//
//    private var footer: some View {
//        HStack(spacing: 10) {
//            ProgressView(value: overallProgress)
//                .tint(.yellow)
//                .background(Color.white.opacity(0.15))
//                .clipShape(Capsule())
//
//            Text(progressComment)
//                .font(.caption2)
//                .foregroundColor(.white.opacity(0.9))
//        }
//    }
//
//    // MARK: - 텍스트/레터
//
//    private var titleText: String {
//        switch mode {
//        case .personal: return "나의 Bible 365"
//        case .team(let name): return "\(name) 팀 챌린지"
//        }
//    }
//
//    private var subtitleText: String {
//        switch mode {
//        case .personal: return "개인 성경 읽기 진행 현황"
//        case .team:     return "팀 전체의 누적 진행 현황"
//        }
//    }
//
//    private var progressComment: String {
//        let p = overallProgress
//
//        switch p {
//        case 0..<0.05:
//            return "이제 막 시작했어요. 천천히 채워볼까요?"
//        case 0.05..<0.3:
//            return "좋아요! 말씀의 빛이 조금씩 번지고 있어요."
//        case 0.3..<0.7:
//            return "꽤 많이 채워졌어요. 꾸준함이 빛나고 있어요."
//        case 0.7..<0.99:
//            return "거의 다 왔어요! 마무리 스퍼트 🔥"
//        default:
//            return "축하합니다! 66권을 모두 채웠어요! 🎉"
//        }
//    }
//
//    private func letter(for index: Int) -> String {
//        switch index {
//        case 0: return "B"
//        case 1: return "I"
//        case 2: return "B"
//        case 3: return "L"
//        case 4: return "E"
//        default: return ""
//        }
//    }
//}
//
