import Foundation
import SwiftUI

@MainActor
final class SubmittableStore: ObservableObject {
    @AppStorage("submittable_api_key") private var storedAPIKey: String = ""

    @Published private(set) var submissions: [Submission] = []
    @Published private(set) var submissionEntries: [String: [SubmissionEntry]] = [:]
    @Published private(set) var forms: [FormSummary] = []
    @Published private(set) var reviews: [Review] = []
    @Published private(set) var paymentDetails: [PaymentDetail] = []
    @Published private(set) var teamMembers: [TeamMember] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: APIError?

    var apiKey: String {
        get { storedAPIKey }
        set {
            storedAPIKey = newValue
            api = SubmittableAPI(apiKey: newValue)
        }
    }

    private var api: SubmittableAPI

    init() {
        api = SubmittableAPI(apiKey: storedAPIKey)
    }

    func refreshAll(force: Bool = false) async {
        guard !isLoading else { return }
        if !force && !submissions.isEmpty { return }
        guard !apiKey.isEmpty else {
            error = .missingAPIKey
            return
        }
        isLoading = true
        defer { isLoading = false }
        error = nil

        async let submissionsTask = api.fetchSubmissions()
        async let formsTask = api.fetchForms()
        async let reviewsTask = api.fetchReviews()
        async let teamTask = api.fetchTeamMembers()

        do {
            let (loadedSubmissions, loadedForms, loadedReviews, loadedTeam) = try await (submissionsTask, formsTask, reviewsTask, teamTask)
            submissions = loadedSubmissions.sorted { ($0.submissionDate ?? "") > ($1.submissionDate ?? "") }
            forms = loadedForms
            reviews = loadedReviews
            teamMembers = loadedTeam

            try await loadEntries(for: submissions)
            try await loadPaymentDetails()
        } catch let apiError as APIError {
            error = apiError
        } catch {
            error = .server(code: -1, message: error.localizedDescription)
        }
    }

    func loadEntries(for submissions: [Submission]) async throws {
        submissionEntries.removeAll()
        for submission in submissions {
            guard let id = submission.submissionId else { continue }
            let entries = try await api.fetchSubmissionEntries(for: id)
            submissionEntries[id] = entries
        }
    }

    func loadPaymentDetails(formId: String? = nil) async throws {
        guard let targetFormId = formId ?? forms.first(where: { ($0.formType ?? "").localizedCaseInsensitiveContains("payment") })?.formId else {
            paymentDetails = []
            return
        }
        paymentDetails = try await api.fetchPaymentDetails(for: targetFormId)
    }

    
    @discardableResult
    func loadPaymentDetailsAndReturn(formId: String) async throws -> [PaymentDetail] {
        let details = try await api.fetchPaymentDetails(for: formId)
        paymentDetails = details
        return details
    }

    func submissions(for organization: String) -> [Submission] {
        submissions.filter { $0.publicOrgName == organization }
    }

    func entries(for submissionId: String) -> [SubmissionEntry] {
        submissionEntries[submissionId] ?? []
    }

    func payments(for submissionId: String) -> [PaymentDetail] {
        paymentDetails.filter { $0.entry.submissionId == submissionId }
    }
}
