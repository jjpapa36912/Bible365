//
//  BibleBookBlockView.swift
//  Bible365
//
//  Created by 김동준 on 11/29/25.
//

import Foundation
import SwiftUI
//
//struct BibleBookBlockView: View {
//    let progress: BibleBookProgress
//    let isCurrent: Bool
//    let mode: BibleProgressMode
//
//    var body: some View {
//        GeometryReader { geo in
//            ZStack(alignment: .leading) {
//                // 배경 베이스
//                RoundedRectangle(cornerRadius: 10)
//                    .fill(Color.white.opacity(0.15))
//
//                // 진행률에 따라 왼쪽에서 채워지는 빛
//                if progress.progress > 0 {
//                    RoundedRectangle(cornerRadius: 10)
//                        .fill(
//                            LinearGradient(
//                                colors: [
//                                    Color.yellow.opacity(0.85),
//                                    Color.white.opacity(0.0)
//                                ],
//                                startPoint: .leading,
//                                endPoint: .trailing
//                            )
//                        )
//                        .frame(width: max(geo.size.width * CGFloat(progress.progress), 8))
//                        .clipped()
//                        .shadow(color: Color.yellow.opacity(0.4),
//                                radius: 8, x: 0, y: 0)
//                }
//
//                // 테두리 (현재 선택된 책이면 더 강조)
//                RoundedRectangle(cornerRadius: 10)
//                    .strokeBorder(isCurrent ? Color.white : Color.white.opacity(0.4),
//                                  lineWidth: isCurrent ? 2 : 1)
//
//                // 텍스트
//                HStack {
//                    Text(progress.book.nameKo)
//                        .font(.system(size: 11, weight: .semibold))
//                        .foregroundColor(.white)
//                        .lineLimit(1)
//                        .minimumScaleFactor(0.7)
//
//                    Spacer()
//
//                    Text("\(Int(progress.progress * 100))%")
//                        .font(.system(size: 9, weight: .medium))
//                        .foregroundColor(.white.opacity(0.9))
//                }
//                .padding(.horizontal, 8)
//            }
//        }
//        .frame(height: 26)
//    }
//}
