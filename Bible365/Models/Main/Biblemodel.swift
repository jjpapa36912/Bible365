//
//  Biblemodel.swift
//  Bible365
//
//  Created by 김동준 on 11/29/25.
//

import Foundation
import SwiftUI

//// 어떤 모드에서 사용하는지 (개인/팀)
//enum BibleProgressMode {
//    case personal
//    case team(name: String)
//}
//
//// 66권 정보
//struct BibleBook: Identifiable {
//    let id: Int          // 0 ~ 65
//    let code: String     // GEN, EXO ...
//    let nameKo: String   // "창세기"
//}
//
//// 진행률 포함 모델
//struct BibleBookProgress: Identifiable {
//    let id: Int
//    let book: BibleBook
//    var progress: Double   // 0.0 ~ 1.0
//}
//
//// 66권 한글 이름 (개인/팀 공통 사용)
//struct BibleBooks {
//    static let all: [BibleBook] = [
//        // 구약
//        .init(id: 0,  code: "GEN", nameKo: "창세기"),
//        .init(id: 1,  code: "EXO", nameKo: "출애굽기"),
//        .init(id: 2,  code: "LEV", nameKo: "레위기"),
//        .init(id: 3,  code: "NUM", nameKo: "민수기"),
//        .init(id: 4,  code: "DEU", nameKo: "신명기"),
//        .init(id: 5,  code: "JOS", nameKo: "여호수아"),
//        .init(id: 6,  code: "JDG", nameKo: "사사기"),
//        .init(id: 7,  code: "RUT", nameKo: "룻기"),
//        .init(id: 8,  code: "1SA", nameKo: "사무엘상"),
//        .init(id: 9,  code: "2SA", nameKo: "사무엘하"),
//        .init(id: 10, code: "1KI", nameKo: "열왕기상"),
//        .init(id: 11, code: "2KI", nameKo: "열왕기하"),
//        .init(id: 12, code: "1CH", nameKo: "역대상"),
//        .init(id: 13, code: "2CH", nameKo: "역대하"),
//        .init(id: 14, code: "EZR", nameKo: "에스라"),
//        .init(id: 15, code: "NEH", nameKo: "느헤미야"),
//        .init(id: 16, code: "EST", nameKo: "에스더"),
//        .init(id: 17, code: "JOB", nameKo: "욥기"),
//        .init(id: 18, code: "PSA", nameKo: "시편"),
//        .init(id: 19, code: "PRO", nameKo: "잠언"),
//        .init(id: 20, code: "ECC", nameKo: "전도서"),
//        .init(id: 21, code: "SNG", nameKo: "아가"),
//        .init(id: 22, code: "ISA", nameKo: "이사야"),
//        .init(id: 23, code: "JER", nameKo: "예레미야"),
//        .init(id: 24, code: "LAM", nameKo: "예레미야애가"),
//        .init(id: 25, code: "EZE", nameKo: "에스겔"),
//        .init(id: 26, code: "DAN", nameKo: "다니엘"),
//        .init(id: 27, code: "HOS", nameKo: "호세아"),
//        .init(id: 28, code: "JOL", nameKo: "요엘"),
//        .init(id: 29, code: "AMO", nameKo: "아모스"),
//        .init(id: 30, code: "OBA", nameKo: "오바댜"),
//        .init(id: 31, code: "JON", nameKo: "요나"),
//        .init(id: 32, code: "MIC", nameKo: "미가"),
//        .init(id: 33, code: "NAH", nameKo: "나훔"),
//        .init(id: 34, code: "HAB", nameKo: "하박국"),
//        .init(id: 35, code: "ZEP", nameKo: "스바냐"),
//        .init(id: 36, code: "HAG", nameKo: "학개"),
//        .init(id: 37, code: "ZEC", nameKo: "스가랴"),
//        .init(id: 38, code: "MAL", nameKo: "말라기"),
//
//        // 신약
//        .init(id: 39, code: "MAT", nameKo: "마태복음"),
//        .init(id: 40, code: "MRK", nameKo: "마가복음"),
//        .init(id: 41, code: "LUK", nameKo: "누가복음"),
//        .init(id: 42, code: "JHN", nameKo: "요한복음"),
//        .init(id: 43, code: "ACT", nameKo: "사도행전"),
//        .init(id: 44, code: "ROM", nameKo: "로마서"),
//        .init(id: 45, code: "1CO", nameKo: "고린도전서"),
//        .init(id: 46, code: "2CO", nameKo: "고린도후서"),
//        .init(id: 47, code: "GAL", nameKo: "갈라디아서"),
//        .init(id: 48, code: "EPH", nameKo: "에베소서"),
//        .init(id: 49, code: "PHP", nameKo: "빌립보서"),
//        .init(id: 50, code: "COL", nameKo: "골로새서"),
//        .init(id: 51, code: "1TH", nameKo: "데살로니가전서"),
//        .init(id: 52, code: "2TH", nameKo: "데살로니가후서"),
//        .init(id: 53, code: "1TI", nameKo: "디모데전서"),
//        .init(id: 54, code: "2TI", nameKo: "디모데후서"),
//        .init(id: 55, code: "TIT", nameKo: "디도서"),
//        .init(id: 56, code: "PHM", nameKo: "빌레몬서"),
//        .init(id: 57, code: "HEB", nameKo: "히브리서"),
//        .init(id: 58, code: "JAS", nameKo: "야고보서"),
//        .init(id: 59, code: "1PE", nameKo: "베드로전서"),
//        .init(id: 60, code: "2PE", nameKo: "베드로후서"),
//        .init(id: 61, code: "1JN", nameKo: "요한1서"),
//        .init(id: 62, code: "2JN", nameKo: "요한2서"),
//        .init(id: 63, code: "3JN", nameKo: "요한3서"),
//        .init(id: 64, code: "JUD", nameKo: "유다서"),
//        .init(id: 65, code: "REV", nameKo: "요한계시록")
//    ]
//}
///// 각 글자에 들어갈 book index 들 (총 66개)
//struct BibleBoardLayout {
//    // B, I, B, L, E 순서
//    static let columns: [[Int]] = [
//        Array(0..<15),           // 첫 B : 창세기 ~ 역대하
//        Array(15..<27),          // I    : 에스라 ~ 다니엘
//        Array(27..<42),          // 두번째 B : 호세아 ~ 마가복음
//        Array(42..<53),          // L    : 누가 ~ 데살후
//        Array(53..<66)           // E    : 디모데전서 ~ 계시록
//    ]
//}
