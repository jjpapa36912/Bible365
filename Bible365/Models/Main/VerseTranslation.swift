//
//  VerseTranslation.swift
//  Bible365
//
//  Created by 김동준 on 11/23/25.
//

import Foundation
import SwiftUI

struct VerseTranslation: Decodable {
    let version: String
    let bookId: String
    let chapter: Int
    let verse: Int
    let lang: String
    let sourceText: String       // 영어
    let translatedText: String   // 한글
    let fromCache: Bool
}
