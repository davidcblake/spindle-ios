import PPDesign
import SwiftUI

/// A place to say what is wrong or what would help, sent straight to Dave's
/// phone (decision `0006` in the Spindle repository).
///
/// Anonymous, like everything else on the iPhone: it carries the words and
/// nothing else, so there is no reply. The screen says so.
struct FeedbackScreen: View {
    @Environment(\.ppTheme) private var theme
    @Environment(\.studyService) private var studyService
    @Environment(Connection.self) private var connection: Connection?
    @State private var message = ""
    @State private var sending = false
    @State private var sent = false
    @State private var failure: StudyFailure?

    private var isOnline: Bool { connection?.isOnline ?? true }

    private var trimmed: String { message.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        Form {
            if sent {
                Section {
                    Label("Thank you — it's on its way.", systemImage: "checkmark.circle")
                        .foregroundStyle(theme.accent)
                    Button("Send something else") {
                        sent = false
                    }
                }
            } else {
                Section {
                    TextField(
                        "What isn't working, or what would make Spindle better for you? Type, or tap the mic on your keyboard and speak…",
                        text: $message,
                        axis: .vertical
                    )
                    .lineLimit(6...)
                    .onChange(of: message) { _, text in
                        if text.count > Feedback.longest { message = String(text.prefix(Feedback.longest)) }
                    }
                } footer: {
                    Text("Sent without your name, so there's no way to reply. If you'd like an answer, include how to reach you.")
                }
                Section {
                    Button(sending ? "Sending…" : "Send") {
                        Task { await send() }
                    }
                    .buttonStyle(.ppProminent)
                    .disabled(sending || trimmed.count < Feedback.shortest || !isOnline)
                    .listRowBackground(Color.clear)
                } footer: {
                    if let failure {
                        Text(failure.userMessage).foregroundStyle(theme.danger)
                    } else if !isOnline {
                        Text("You're offline — sending needs a connection.")
                    }
                }
            }
        }
        .tint(theme.accent)
        .navigationTitle("Feedback")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func send() async {
        sending = true
        failure = nil
        defer { sending = false }
        do throws(StudyFailure) {
            try await studyService.sendFeedback(Feedback(message: trimmed))
            message = ""
            sent = true
        } catch {
            failure = error
        }
    }
}
