import Foundation

// MARK: - Core Submittable Models

struct Submission: Identifiable, Codable, Hashable {
    var id: String { submissionId ?? UUID().uuidString }
    let submissionId: String?
    let submissionTitle: String?
    let projectTitle: String?
    let submissionStatus: String?
    let submissionDate: String?
    let reviewStageId: String?
    let submitterFirstName: String?
    let submitterLastName: String?
    let submitterEmail: String?
    let publicOrgId: String?
    let publicOrgName: String?
    let submissionUrl: String?

    enum CodingKeys: String, CodingKey {
        case submissionId, submissionTitle, projectTitle, submissionStatus, submissionDate
        case reviewStageId, submitterFirstName, submitterLastName, submitterEmail
        case publicOrgId, publicOrgName, submissionUrl
    }
}

struct SubmissionListResponse: Codable {
    let continuationToken: String?
    let items: [Submission]?
}

struct SubmissionEntry: Codable, Identifiable, Hashable {
    var id: String { entry.entryId ?? UUID().uuidString }
    let formType: String?
    let entry: FormEntry
}

struct SubmissionEntryListResponse: Codable {
    let continuationToken: String?
    let formEntries: [SubmissionEntry]?
}

struct FormEntry: Codable, Hashable {
    let submissionId: String?
    let entryId: String?
    let formId: String?
    let status: String?
    let completedAt: String?
    let createdAt: String?
    let createdBy: String?
    let deadline: String?
    let entryVersionId: String?
    let fieldData: [FormFieldData]?
}

struct FormFieldData: Codable, Identifiable, Hashable {
    var id: String { formFieldId ?? UUID().uuidString }
    let value: String?
    let fieldType: String?
    let formFieldId: String?
    let options: [String]?
    let fileUrl: String?
    let fileName: String?
    let routingNumber: String?
    let confirmRoutingNumber: String?
    let accountNumber: String?
    let confirmAccountNumber: String?

    enum CodingKeys: String, CodingKey {
        case value, fieldType, formFieldId, options
        case fileUrl, fileName, routingNumber, confirmRoutingNumber
        case accountNumber, confirmAccountNumber
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let stringValue = try? container.decode(String.self, forKey: .value) {
            value = stringValue
        } else if let doubleValue = try? container.decode(Double.self, forKey: .value) {
            value = String(doubleValue)
        } else {
            value = nil
        }
        fieldType = try? container.decode(String.self, forKey: .fieldType)
        formFieldId = try? container.decode(String.self, forKey: .formFieldId)
        options = try? container.decode([String].self, forKey: .options)
        fileUrl = try? container.decode(String.self, forKey: .fileUrl)
        fileName = try? container.decode(String.self, forKey: .fileName)
        routingNumber = try? container.decode(String.self, forKey: .routingNumber)
        confirmRoutingNumber = try? container.decode(String.self, forKey: .confirmRoutingNumber)
        accountNumber = try? container.decode(String.self, forKey: .accountNumber)
        confirmAccountNumber = try? container.decode(String.self, forKey: .confirmAccountNumber)
    }
}

// MARK: - Payment Detail Models

struct PaymentDetailListResponse: Codable {
    let continuationToken: String?
    let items: [PaymentDetail]?
}

struct PaymentDetail: Codable, Identifiable, Hashable {
    var id: String { entry.entryId ?? UUID().uuidString }
    let formType: String?
    let entry: PaymentEntry
}

struct PaymentEntry: Codable, Hashable {
    let submissionId: String?
    let entryId: String?
    let formId: String?
    let status: String?
    let completedAt: String?
    let createdAt: String?
    let deadline: String?
    let entryVersionId: String?
    let fieldData: [FieldData]?
}

struct FieldData: Codable, Identifiable, Hashable {
    var id: String { formFieldId ?? UUID().uuidString }
    let value: String?
    let fieldType: String?
    let formFieldId: String?
    let routingNumber: String?
    let confirmRoutingNumber: String?
    let accountNumber: String?
    let confirmAccountNumber: String?
    let options: [String]?

    enum CodingKeys: String, CodingKey {
        case value, fieldType, formFieldId, routingNumber, confirmRoutingNumber
        case accountNumber, confirmAccountNumber, options
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let stringValue = try? container.decode(String.self, forKey: .value) {
            value = stringValue
        } else if let doubleValue = try? container.decode(Double.self, forKey: .value) {
            value = String(doubleValue)
        } else {
            value = nil
        }
        fieldType = try? container.decode(String.self, forKey: .fieldType)
        formFieldId = try? container.decode(String.self, forKey: .formFieldId)
        routingNumber = try? container.decode(String.self, forKey: .routingNumber)
        confirmRoutingNumber = try? container.decode(String.self, forKey: .confirmRoutingNumber)
        accountNumber = try? container.decode(String.self, forKey: .accountNumber)
        confirmAccountNumber = try? container.decode(String.self, forKey: .confirmAccountNumber)
        options = try? container.decode([String].self, forKey: .options)
    }
}

// MARK: - Form Catalog Models

struct FormSummary: Codable, Identifiable, Hashable {
    var id: String { formId ?? UUID().uuidString }
    let formId: String?
    let name: String?
    let formType: String?
    let status: String?
    let description: String?
}

struct FormCatalogResponse: Codable {
    let continuationToken: String?
    let items: [FormSummary]?
}

// MARK: - Review Models

struct Review: Codable, Identifiable, Hashable {
    var id: String { reviewId ?? UUID().uuidString }
    let reviewId: String?
    let entryId: String?
    let reviewStageId: String?
    let reviewerId: String?
    let score: Double?
    let status: String?
    let submittedAt: String?
    let comments: [ReviewComment]?
}

struct ReviewComment: Codable, Identifiable, Hashable {
    var id: String { commentId ?? UUID().uuidString }
    let commentId: String?
    let questionId: String?
    let value: String?
}

struct ReviewListResponse: Codable {
    let continuationToken: String?
    let items: [Review]?
}

// MARK: - Team Members

struct TeamMember: Codable, Identifiable, Hashable {
    var id: String { userId ?? UUID().uuidString }
    let userId: String?
    let firstName: String?
    let lastName: String?
    let email: String?
    let role: String?
    let status: String?
}

struct TeamMemberListResponse: Codable {
    let continuationToken: String?
    let items: [TeamMember]?
}

// MARK: - Helper Extensions

extension Array where Element == FieldData {
    func firstValue(matching index: Int) -> String {
        guard indices.contains(index) else { return "N/A" }
        return self[index].value ?? "N/A"
    }
}

extension String {
    func prettified() -> String {
        guard !isEmpty else { return self }
        return split(separator: "_").map { $0.capitalized }.joined(separator: " ")
    }
}
