import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: SubmittableStore
    @State private var showingSettings = false
    @State private var filterText: String = ""

    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.bar.xaxis")
                }

            SubmissionListView(filterText: $filterText)
                .tabItem {
                    Label("Submissions", systemImage: "tray.full")
                }

            FormCatalogView()
                .tabItem {
                    Label("Forms", systemImage: "doc.append")
                }

            ReviewsView()
                .tabItem {
                    Label("Reviews", systemImage: "star.bubble")
                }
        }
        .task {
            if store.submissions.isEmpty {
                await store.refreshAll()
            }
        }
        .toolbarBackground(.visible, for: .tabBar)
        .overlay(alignment: .bottomTrailing) {
            Button {
                showingSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(14)
                    .background(Circle().fill(Color.accentColor))
                    .shadow(radius: 4)
            }
            .padding()
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
    }
}

// MARK: - Dashboard

struct DashboardView: View {
    @EnvironmentObject private var store: SubmittableStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if store.isLoading {
                        ProgressView("Syncing Submittable data…")
                            .frame(maxWidth: .infinity)
                    }

                    if let error = store.error {
                        Label(error.localizedDescription, systemImage: "exclamationmark.triangle")
                            .foregroundColor(.orange)
                            .padding(.vertical, 4)
                            .padding(.horizontal)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(8)
                    }

                    MetricsGrid()
                    OrganizationSummary()
                    ReviewSummary()
                }
                .padding()
            }
            .navigationTitle("Mission Control")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Refresh") {
                        Task { await store.refreshAll(force: true) }
                    }
                }
            }
        }
    }
}

struct MetricsGrid: View {
    @EnvironmentObject private var store: SubmittableStore

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 16)], spacing: 16) {
            MetricTile(title: "Submissions", value: store.submissions.count, icon: "tray.full.fill", color: .blue)
            MetricTile(title: "Forms", value: store.forms.count, icon: "doc.append", color: .purple)
            MetricTile(title: "Reviews", value: store.reviews.count, icon: "star.bubble.fill", color: .yellow)
            MetricTile(title: "Team", value: store.teamMembers.count, icon: "person.2.fill", color: .green)
        }
    }
}

struct MetricTile: View {
    let title: String
    let value: Int
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(.white)
                .padding(12)
                .background(Circle().fill(color.gradient))
            Text(title)
                .font(.headline)
            Text("\(value)")
                .font(.system(size: 32, weight: .bold))
                .monospacedDigit()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 16).fill(.thinMaterial))
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)
    }
}

struct OrganizationSummary: View {
    @EnvironmentObject private var store: SubmittableStore

    private var grouped: [(organization: String, submissions: [Submission])] {
        Dictionary(grouping: store.submissions) { $0.publicOrgName ?? "Unassigned" }
            .sorted { $0.key < $1.key }
            .map { (organization: $0.key, submissions: $0.value) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Organizations")
                    .font(.title2.bold())
                Spacer()
                Text("Tap for submission details")
                    .foregroundStyle(.secondary)
                    .font(.callout)
            }

            ForEach(grouped, id: \.organization) { org in
                NavigationLink(value: org.organization) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(org.organization)
                                .font(.headline)
                            Text("\(org.submissions.count) submissions")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.tertiary)
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)))
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                }
            }
        }
        .navigationDestination(for: String.self) { organization in
            OrganizationDetailView(organization: organization)
        }
    }
}

struct OrganizationDetailView: View {
    let organization: String
    @EnvironmentObject private var store: SubmittableStore

    var body: some View {
        List {
            ForEach(store.submissions(for: organization)) { submission in
                SubmissionRow(submission: submission)
            }
        }
        .navigationTitle(organization)
    }
}

struct ReviewSummary: View {
    @EnvironmentObject private var store: SubmittableStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Review Insights")
                .font(.title2.bold())
            if store.reviews.isEmpty {
                ContentUnavailableView("No reviews yet", systemImage: "star")
            } else {
                let grouped = Dictionary(grouping: store.reviews) { $0.status ?? "unknown" }
                ForEach(grouped.keys.sorted(), id: \.self) { status in
                    let items = grouped[status] ?? []
                    HStack {
                        VStack(alignment: .leading) {
                            Text(status.prettified())
                                .font(.headline)
                            Text("\(items.count) reviews")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(avgScore(for: items), format: .number.precision(.fractionLength(2)))
                            .monospacedDigit()
                            .font(.title3.bold())
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)))
                }
            }
        }
    }

    private func avgScore(for items: [Review]) -> Double {
        let scores = items.compactMap { $0.score }
        guard !scores.isEmpty else { return 0 }
        return scores.reduce(0, +) / Double(scores.count)
    }
}

// MARK: - Submissions

struct SubmissionListView: View {
    @EnvironmentObject private var store: SubmittableStore
    @Binding var filterText: String

    private var filteredSubmissions: [Submission] {
        guard !filterText.isEmpty else { return store.submissions }
        return store.submissions.filter { submission in
            [submission.submissionTitle, submission.projectTitle, submission.publicOrgName]
                .compactMap { $0 }
                .contains { $0.localizedCaseInsensitiveContains(filterText) }
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if store.isLoading && store.submissions.isEmpty {
                        ProgressView()
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    ForEach(filteredSubmissions) { submission in
                        NavigationLink {
                            SubmissionDetailView(submission: submission)
                        } label: {
                            SubmissionRow(submission: submission)
                        }
                    }
                }
            }
            .navigationTitle("Submissions")
            .searchable(text: $filterText, placement: .navigationBarDrawer(displayMode: .always))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Refresh") {
                        Task { await store.refreshAll(force: true) }
                    }
                }
            }
        }
    }
}

struct SubmissionRow: View {
    let submission: Submission

    private var statusColor: Color {
        switch submission.submissionStatus?.lowercased() {
        case "approved": return .green
        case "pending": return .orange
        case "declined", "rejected": return .red
        default: return .secondary
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(submission.submissionTitle ?? "Untitled Submission")
                .font(.headline)
            if let organization = submission.publicOrgName {
                Text(organization)
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 12) {
                if let status = submission.submissionStatus {
                    Label(status.prettified(), systemImage: "smallcircle.filled.circle")
                        .foregroundStyle(statusColor)
                        .labelStyle(.titleAndIcon)
                }
                if let date = submission.submissionDate {
                    Label(date, systemImage: "calendar")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

struct SubmissionDetailView: View {
    let submission: Submission
    @EnvironmentObject private var store: SubmittableStore
    @State private var selection: SubmissionEntry?

    private var entries: [SubmissionEntry] {
        store.entries(for: submission.submissionId ?? "")
    }

    private var payments: [PaymentDetail] {
        store.payments(for: submission.submissionId ?? "")
    }

    var body: some View {
        Form {
            Section("Overview") {
                LabeledContent("Title", value: submission.submissionTitle ?? "—")
                LabeledContent("Project", value: submission.projectTitle ?? "—")
                LabeledContent("Status", value: submission.submissionStatus?.prettified() ?? "—")
                LabeledContent("Submitted", value: submission.submissionDate ?? "—")
                LabeledContent("Organization", value: submission.publicOrgName ?? "—")
                LabeledContent("Submitter", value: "\(submission.submitterFirstName ?? "") \(submission.submitterLastName ?? "")")
                LabeledContent("Email", value: submission.submitterEmail ?? "—")
            }

            if !entries.isEmpty {
                Section("Associated Forms") {
                    ForEach(entries) { entry in
                        Button(entry.formType?.prettified() ?? "Form") {
                            selection = entry
                        }
                    }
                }
            }

            if !payments.isEmpty {
                Section("Payment Details") {
                    ForEach(payments) { detail in
                        PaymentDetailView(detail: detail)
                    }
                }
            }

            if let link = submission.submissionUrl, let url = URL(string: link) {
                Section { Link("Open in Submittable", destination: url) }
            }
        }
        .navigationTitle(submission.submissionTitle ?? "Submission")
        .sheet(item: $selection) { entry in
            EntryDetailView(entry: entry)
        }
    }
}

// MARK: - Entry Detail

struct EntryDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let entry: SubmissionEntry

    var body: some View {
        NavigationStack {
            List {
                Section("Form Metadata") {
                    LabeledContent("Type", value: entry.formType?.prettified() ?? "—")
                    LabeledContent("Status", value: entry.entry.status ?? "—")
                    LabeledContent("Submitted", value: entry.entry.completedAt ?? "—")
                    LabeledContent("Deadline", value: entry.entry.deadline ?? "—")
                }

                Section("Fields") {
                    ForEach(entry.entry.fieldData ?? []) { field in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(field.fieldType?.prettified() ?? "Field")
                                .font(.headline)
                            if let value = field.value, !value.isEmpty {
                                Text(value)
                            }
                            if let file = field.fileUrl, let url = URL(string: file) {
                                Link(field.fileName ?? "View Attachment", destination: url)
                            }
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
            .navigationTitle(entry.formType?.prettified() ?? "Form")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Payment Detail

struct PaymentDetailView: View {
    let detail: PaymentDetail

    private var routing: String {
        detail.entry.fieldData?.first(where: { $0.fieldType == "bank_details" })?.routingNumber ?? "—"
    }

    private var account: String {
        detail.entry.fieldData?.first(where: { $0.fieldType == "bank_details" })?.accountNumber ?? "—"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(detail.formType?.prettified() ?? "Payment Form")
                .font(.headline)
            Text("Status: \(detail.entry.status ?? "—")")
            Text("Routing: \(routing)")
            Text("Account: \(account)")
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Form Catalog

struct FormCatalogView: View {
    @EnvironmentObject private var store: SubmittableStore

    var body: some View {
        NavigationStack {
            List(store.forms) { form in
                NavigationLink(form.name ?? "Untitled") {
                    FormDetailView(form: form)
                }
            }
            .navigationTitle("Forms")
        }
    }
}

struct FormDetailView: View {
    let form: FormSummary
    @EnvironmentObject private var store: SubmittableStore
    @State private var paymentDetails: [PaymentDetail] = []

    var body: some View {
        List {
            Section("Metadata") {
                LabeledContent("Name", value: form.name ?? "—")
                LabeledContent("Type", value: form.formType?.prettified() ?? "—")
                LabeledContent("Status", value: form.status?.prettified() ?? "—")
                LabeledContent("Description", value: form.description ?? "—")
            }

            if !paymentDetails.isEmpty {
                Section("Entries") {
                    ForEach(paymentDetails) { detail in
                        PaymentDetailView(detail: detail)
                    }
                }
            }
        }
        .navigationTitle(form.name ?? "Form")
        .task { await loadEntries() }
    }

    private func loadEntries() async {
        guard let id = form.formId else { return }
        do {
            paymentDetails = store.paymentDetails.filter { $0.entry.formId == id }
            if paymentDetails.isEmpty {
                paymentDetails = try await store.loadPaymentDetailsAndReturn(formId: id)
            }
        } catch {
            // ignore for now
        }
    }
}

// MARK: - Reviews

struct ReviewsView: View {
    @EnvironmentObject private var store: SubmittableStore

    var body: some View {
        NavigationStack {
            if store.reviews.isEmpty {
                ContentUnavailableView("No review data", systemImage: "star")
                    .navigationTitle("Reviews")
            } else {
                List(store.reviews) { review in
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Stage: \(review.reviewStageId ?? "—")")
                            .font(.headline)
                        Text("Status: \(review.status?.prettified() ?? "—")")
                            .foregroundStyle(.secondary)
                        if let score = review.score {
                            Text("Score: \(score, format: .number.precision(.fractionLength(2)))")
                                .monospacedDigit()
                        }
                        if let submitted = review.submittedAt {
                            Text("Submitted: \(submitted)")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 6)
                }
                .navigationTitle("Reviews")
            }
        }
    }
}

// MARK: - Settings

struct SettingsView: View {
    @EnvironmentObject private var store: SubmittableStore
    @Environment(\.dismiss) private var dismiss
    @State private var apiKey: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Authentication") {
                    SecureField("Submittable API Key", text: $apiKey)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                Section("Sync") {
                    Button("Refresh Data") {
                        store.apiKey = apiKey
                        Task { await store.refreshAll(force: true) }
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.apiKey = apiKey
                        dismiss()
                    }
                }
            }
            .onAppear { apiKey = store.apiKey }
        }
    }
}
