
import Foundation

// MARK: - 서버 DTO 모델들

struct TeamFriendDTO: Codable, Identifiable {
    let id: Int      // User.id (Long)
    let name: String // 닉네임
}

struct TeamResponseDTO: Codable {
    let id: Int
    let name: String
    let status: String           // "ACTIVE" / "COMPLETED"
    let startedAt: String?
    let completedAt: String?

    let members: [TeamMemberDTO]
    let assignments: [TeamBookAssignmentDTO]
    let completedBookIndices: [Int]?
}

struct TeamMemberDTO: Codable {
    let userId: Int
    let nickname: String
    let leader: Bool
}

struct TeamBookAssignmentDTO: Codable {
    let bookIndex: Int
    let bookCode: String?
    let userId: Int
    let nickname: String
}

struct CreateTeamRequestDTO: Codable {
    let teamName: String
    let memberIds: [Int]
}

struct BookFinishedRequestDTO: Codable {
    let teamId: Int
    let bookIndex: Int
}

struct TeamHistoryDTO: Codable, Identifiable {
    let id: Int
    let teamName: String
    let completedAt: String?

    let memberBooks: [TeamHistoryMemberBooksDTO]
}

struct TeamHistoryMemberBooksDTO: Codable {
    let userId: Int
    let nickname: String
    let bookIndices: [Int]
}

// MARK: - 에러 정의

enum TeamChallengeAPIError: Error {
    case notAuthenticated
    case invalidURL
    case httpError(status: Int, message: String?)
    case decodeError(Error)
    case encodeError(Error)
    case unknown
}

// MARK: - TeamChallengeAPI

final class TeamChallengeAPI {

    static let shared = TeamChallengeAPI()

    private let baseURL: URL = {
        #if DEBUG
        return URL(string: "http://127.0.0.1:8080")!
        #else
        return URL(string: "http://13.124.208.108:8080")!
        #endif
    }()

    private let jsonDecoder: JSONDecoder
    private let jsonEncoder: JSONEncoder

    private init() {
        let decoder = JSONDecoder()
        jsonDecoder = decoder

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        jsonEncoder = encoder
    }

    // MARK: - 토큰 가져오기 (지금은 사용 X, 필요 시 사용)

    private func getAccessToken() -> String? {
        return AuthAPI.shared.currentAccessToken
    }

    // 현재 로그인한 userId (문자열)
    private func currentLoginUserId() -> String? {
        UserDefaults.standard.string(forKey: "userId")
    }

    // MARK: - 공통 요청 빌더
    // 👉 authHeader는 기본 false (팀 챌린지 API는 토큰 안 붙임)
    // MARK: - 6) 내가 속한 팀 전체 조회
    // GET /api/team/my-teams?userId=...

    // MARK: - 6) 내가 속한 팀 전체 조회
    // GET /api/team/my-teams?userId=...

    func fetchMyTeams() async throws -> [TeamResponseDTO] {
        guard let loginUserId = currentLoginUserId(), !loginUserId.isEmpty else {
            throw TeamChallengeAPIError.notAuthenticated
        }

        let encodedUserId = loginUserId.addingPercentEncoding(
            withAllowedCharacters: .urlQueryAllowed
        ) ?? loginUserId

        let request = try makeRequest(
            path: "/api/team/my-teams?userId=\(encodedUserId)",
            method: "GET",
            body: nil as EmptyBody?,
            authHeader: false
        )

        return try await sendRequest(request, as: [TeamResponseDTO].self)
    }


    private func makeRequest(
        path: String,
        method: String = "GET",
        body: Encodable? = nil,
        authHeader: Bool = false
    ) throws -> URLRequest {

        guard let url = URL(string: path, relativeTo: baseURL) else {
            throw TeamChallengeAPIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = 15

        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if authHeader, let token = getAccessToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body = body {
            do {
                let data = try jsonEncoder.encode(AnyEncodable(body))
                request.httpBody = data
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            } catch {
                throw TeamChallengeAPIError.encodeError(error)
            }
        }

        return request
    }

    // MARK: - 공통 호출

    private func sendRequest<T: Decodable>(_ request: URLRequest, as type: T.Type) async throws -> T {
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw TeamChallengeAPIError.unknown
        }

        guard (200..<300).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8)
            throw TeamChallengeAPIError.httpError(status: http.statusCode, message: message)
        }

        do {
            return try jsonDecoder.decode(T.self, from: data)
        } catch {
            throw TeamChallengeAPIError.decodeError(error)
        }
    }

    private func sendRequestNoBody(_ request: URLRequest) async throws {
        let (_, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw TeamChallengeAPIError.unknown
        }

        guard (200..<300).contains(http.statusCode) else {
            throw TeamChallengeAPIError.httpError(status: http.statusCode, message: nil)
        }
    }

    // MARK: - 1) 친구 후보 목록
    // GET /api/team/friends?userId=...

    func fetchFriends() async throws -> [TeamFriendDTO] {
        guard let loginUserId = currentLoginUserId(), !loginUserId.isEmpty else {
            throw TeamChallengeAPIError.notAuthenticated
        }

        let encodedUserId = loginUserId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? loginUserId

        let request = try makeRequest(
            path: "/api/team/friends?userId=\(encodedUserId)",
            method: "GET",
            body: nil as EmptyBody?,
            authHeader: false
        )

        return try await sendRequest(request, as: [TeamFriendDTO].self)
    }

    // MARK: - 2) 팀 생성
    // POST /api/team?userId=...

    func createTeam(teamName: String, memberIds: [Int]) async throws -> TeamResponseDTO {
        guard let loginUserId = currentLoginUserId(), !loginUserId.isEmpty else {
            throw TeamChallengeAPIError.notAuthenticated
        }

        let encodedUserId = loginUserId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? loginUserId

        let body = CreateTeamRequestDTO(teamName: teamName, memberIds: memberIds)

        let request = try makeRequest(
            path: "/api/team?userId=\(encodedUserId)",
            method: "POST",
            body: body,
            authHeader: false
        )

        return try await sendRequest(request, as: TeamResponseDTO.self)
    }

    // MARK: - 3) 내 ACTIVE 팀 조회
    // GET /api/team/active?userId=...
    // TeamChallengeAPI.swift 중 일부

    // MARK: - 3) 내 ACTIVE 팀 조회
    // GET /api/team/active?userId=...

    func fetchActiveTeam() async throws -> TeamResponseDTO? {
        guard let loginUserId = currentLoginUserId(), !loginUserId.isEmpty else {
            throw TeamChallengeAPIError.notAuthenticated
        }

        let encodedUserId = loginUserId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
            ?? loginUserId

        // 공통 makeRequest 활용
        let request = try makeRequest(
            path: "/api/team/active?userId=\(encodedUserId)",
            method: "GET",
            body: nil as EmptyBody?,
            authHeader: false   // 👉 다른 팀 API와 동일하게 토큰 안 붙임
        )

        do {
            let dto = try await sendRequest(request, as: TeamResponseDTO.self)
            return dto
        } catch TeamChallengeAPIError.httpError(let status, _) where status == 404 {
            // ACTIVE 팀이 없는 경우 → nil 리턴
            return nil
        }
    }


    // MARK: - 4) 책 완독 이벤트
    // POST /api/team/progress/book-finished?userId=...

    func markBookFinished(teamId: Int, bookIndex: Int) async throws -> TeamResponseDTO {
        guard let loginUserId = currentLoginUserId(), !loginUserId.isEmpty else {
            throw TeamChallengeAPIError.notAuthenticated
        }

        let encodedUserId = loginUserId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? loginUserId

        let body = BookFinishedRequestDTO(teamId: teamId, bookIndex: bookIndex)

        let request = try makeRequest(
            path: "/api/team/progress/book-finished?userId=\(encodedUserId)",
            method: "POST",
            body: body,
            authHeader: false
        )

        return try await sendRequest(request, as: TeamResponseDTO.self)
    }

    // MARK: - 5) 완료된 팀 히스토리 / 랭킹
    // GET /api/team/history

    func fetchHistory() async throws -> [TeamHistoryDTO] {
        let request = try makeRequest(
            path: "/api/team/history",
            method: "GET",
            body: nil as EmptyBody?,
            authHeader: false
        )

        return try await sendRequest(request, as: [TeamHistoryDTO].self)
    }
}

// MARK: - 유틸

private struct EmptyBody: Codable {}

private struct AnyEncodable: Encodable {
    private let _encode: (Encoder) throws -> Void

    init<T: Encodable>(_ wrapped: T) {
        _encode = wrapped.encode
    }

    func encode(to encoder: Encoder) throws {
        try _encode(encoder)
    }
}
