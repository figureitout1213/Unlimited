import Foundation

struct SubmittableAPI {
    enum Endpoint {
        case submissions
        case submissionEntries(submissionId: String)
        case forms
        case paymentForms(formId: String)
        case reviews
        case teamMembers

        var path: String {
            switch self {
            case .submissions:
                return "/v4/submissions"
            case .submissionEntries(let submissionId):
                return "/v4/entries/submissions/\(submissionId)"
            case .forms:
                return "/v4/forms"
            case .paymentForms(let formId):
                return "/v4/entries/forms/\(formId)"
            case .reviews:
                return "/v4/reviews"
            case .teamMembers:
                return "/v4/team-members"
            }
        }
    }

    private let session: URLSession
    private let baseURL: URL
    private var apiKey: String

    init(apiKey: String, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
        self.baseURL = URL(string: "https://submittable-api.submittable.com")!
    }

    mutating func update(apiKey: String) {
        self.apiKey = apiKey
    }

    func fetchCollection<Response: ContinuationResponse>(endpoint: Endpoint, pageSize: Int = 200, as type: Response.Type) async throws -> [Response.Item] {
        guard !apiKey.isEmpty else { throw APIError.missingAPIKey }
        var results: [Response.Item] = []
        var continuation: String? = nil
        repeat {
            var components = URLComponents(url: baseURL.appendingPathComponent(endpoint.path), resolvingAgainstBaseURL: false)
            var queryItems = [URLQueryItem(name: "size", value: "\(pageSize)")]
            if let token = continuation {
                queryItems.append(URLQueryItem(name: "continuationToken", value: token))
            }
            components?.queryItems = queryItems

            guard let url = components?.url else { break }
            let request = makeRequest(url: url)
            let (data, response) = try await session.data(for: request)
            try validate(response: response, data: data)

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let decoded = try decoder.decode(type, from: data)
            results.append(contentsOf: decoded.items ?? [])
            continuation = decoded.continuationToken
            if decoded.items?.count ?? 0 < pageSize {
                break
            }
        } while continuation != nil
        return results
    }

    func fetchSubmissions() async throws -> [Submission] {
        try await fetchCollection(endpoint: .submissions, as: SubmissionListResponse.self)
    }

    func fetchSubmissionEntries(for submissionId: String) async throws -> [SubmissionEntry] {
        try await fetchCollection(endpoint: .submissionEntries(submissionId: submissionId), as: SubmissionEntryListResponse.self)
    }

    func fetchForms() async throws -> [FormSummary] {
        try await fetchCollection(endpoint: .forms, as: FormCatalogResponse.self)
    }

    func fetchPaymentDetails(for formId: String) async throws -> [PaymentDetail] {
        try await fetchCollection(endpoint: .paymentForms(formId: formId), as: PaymentDetailListResponse.self)
    }

    func fetchReviews() async throws -> [Review] {
        try await fetchCollection(endpoint: .reviews, as: ReviewListResponse.self)
    }

    func fetchTeamMembers() async throws -> [TeamMember] {
        try await fetchCollection(endpoint: .teamMembers, as: TeamMemberListResponse.self)
    }

    private func makeRequest(url: URL) -> URLRequest {
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 60)
        request.httpMethod = "GET"
        let token = Data("\(apiKey):".utf8).base64EncodedString()
        request.setValue("Basic \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        return request
    }

    private func validate(response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else { return }
        guard (200...299).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw APIError.server(code: http.statusCode, message: message)
        }
    }
}

// MARK: - Continuation Helpers

protocol ContinuationResponse: Decodable {
    associatedtype Item
    var continuationToken: String? { get }
    var items: [Item]? { get }
}

enum APIError: LocalizedError {
    case missingAPIKey
    case server(code: Int, message: String)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Add a Submittable API key to start syncing."
        case .server(let code, let message):
            return "Server error (\(code)): \(message)"
        }
    }
}

extension SubmissionListResponse: ContinuationResponse {
    typealias Item = Submission
}

extension SubmissionEntryListResponse: ContinuationResponse {
    typealias Item = SubmissionEntry
}

extension PaymentDetailListResponse: ContinuationResponse {
    typealias Item = PaymentDetail
}

extension FormCatalogResponse: ContinuationResponse {
    typealias Item = FormSummary
}

extension ReviewListResponse: ContinuationResponse {
    typealias Item = Review
}

extension TeamMemberListResponse: ContinuationResponse {
    typealias Item = TeamMember
}
