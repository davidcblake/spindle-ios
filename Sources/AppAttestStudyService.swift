import CryptoKit
import DeviceCheck
import Foundation

/// Prepares a study by asking Spindle's server, proving with Apple's App
/// Attest that the request comes from a genuine copy of Spindle on a real
/// iPhone. Decisions `0002` and `0003` in the Spindle repository.
///
/// No account, no personal identifier: the key identifies an install, not a
/// person, and lives in the Secure Enclave.
struct AppAttestStudyService: StudyService {
    let server: URL
    let session: URLSession

    init(server: URL, session: URLSession = .shared) {
        self.server = server
        self.session = session
    }

    private var defaults: UserDefaults { .standard }

    /// The key id is not a secret — the server already knows it, and it is
    /// useless without the Secure Enclave key it names — so it is kept in
    /// ordinary settings rather than the Keychain.
    private static let keyIdSetting = "appAttestKeyId"

    func prepare(_ request: StudyRequest) async throws(StudyFailure) -> Study {
        let reply: StudyReply = try await ask("api/app/study", request)
        return reply.study
    }

    func preparePlan(_ request: PlanRequest) async throws(StudyFailure) -> GeneratedPlan {
        let reply: PlanReply = try await ask("api/app/plan", request)
        return reply.plan
    }

    func sendFeedback(_ feedback: Feedback) async throws(StudyFailure) {
        let _: NoReply = try await ask("api/app/feedback", feedback)
    }

    /// Sends one attested request and reads the reply.
    private func ask<Request: Encodable, Reply: Decodable & Sendable>(
        _ path: String, _ request: Request
    ) async throws(StudyFailure) -> Reply {
        guard DCAppAttestService.shared.isSupported else {
            // The simulator, and devices too old for App Attest. Fails closed,
            // as `0002` intends.
            throw StudyFailure("Preparing a study needs an iPhone that can prove it is running Spindle. Everything already in your journal works.")
        }
        let body: Data
        do {
            body = try JSONEncoder().encode(request)
        } catch {
            throw StudyFailure("Spindle couldn't put that request together.", log: String(describing: error))
        }

        do {
            return try await send(body, to: path)
        } catch let failure as StudyFailure where failure == .keyRejected {
            // Apple or the server no longer accepts the key (a reinstall,
            // a restore to a new phone). Start again with a new one, once.
            defaults.removeObject(forKey: Self.keyIdSetting)
            do {
                return try await send(body, to: path)
            } catch {
                throw Self.failure(from: error)
            }
        } catch {
            throw Self.failure(from: error)
        }
    }

    private func send<Reply: Decodable>(_ body: Data, to path: String) async throws -> Reply {
        let keyId = try await registeredKey()
        let assertion: Data
        do {
            assertion = try await DCAppAttestService.shared.generateAssertion(
                keyId,
                clientDataHash: Data(SHA256.hash(data: body))
            )
        } catch let error as DCError where error.code == .invalidKey {
            throw StudyFailure.keyRejected
        }

        var request = URLRequest(url: server.appending(path: path))
        request.httpMethod = "POST"
        // Past the server's own sixty seconds, so a slow connection shows the
        // server's real answer rather than giving up first. The web app's number.
        request.timeoutInterval = 90
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(keyId, forHTTPHeaderField: "X-Spindle-Key-Id")
        request.setValue(assertion.base64EncodedString(), forHTTPHeaderField: "X-Spindle-Assertion")
        request.httpBody = body

        let (data, response) = try await session.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        if (200..<300).contains(status) {
            if let reply = try? JSONDecoder().decode(Reply.self, from: data) { return reply }
            // Feedback is answered with an empty 204, which is the whole reply.
            if let nothing = NoReply() as? Reply { return nothing }
        }
        if let problem = try? JSONDecoder().decode(ErrorReply.self, from: data) {
            if problem.error.type == "attestation", status == 401 {
                throw StudyFailure.keyRejected
            }
            throw StudyFailure(problem.error.message, log: "\(status) \(problem.error.type ?? "error"): \(problem.error.message)")
        }
        throw StudyFailure("The study service returned an empty response — tap again.", log: "HTTP \(status), \(data.count) bytes")
    }

    /// The install's attested key, registering one with the server the first
    /// time.
    private func registeredKey() async throws -> String {
        if let keyId = defaults.string(forKey: Self.keyIdSetting) {
            return keyId
        }
        let challengeReply: ChallengeReply = try await get("api/app/challenge")
        guard let challenge = Data(base64Encoded: challengeReply.challenge) else {
            throw StudyFailure("The study service sent something Spindle couldn't read — tap again.", log: "challenge was not base64")
        }
        let keyId = try await DCAppAttestService.shared.generateKey()
        let attestation = try await DCAppAttestService.shared.attestKey(
            keyId,
            clientDataHash: Data(SHA256.hash(data: challenge))
        )

        var request = URLRequest(url: server.appending(path: "api/app/register"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode([
            "keyId": keyId,
            "attestation": attestation.base64EncodedString(),
            "challenge": challengeReply.challenge,
        ])
        let (data, response) = try await session.data(for: request)
        guard let status = (response as? HTTPURLResponse)?.statusCode, (200..<300).contains(status) else {
            let message = (try? JSONDecoder().decode(ErrorReply.self, from: data))?.error.message
            throw StudyFailure(
                message ?? "Spindle couldn't register this iPhone with the study service — try again later. Your journal is unaffected.",
                log: "register failed: \(String(decoding: data, as: UTF8.self))"
            )
        }
        defaults.set(keyId, forKey: Self.keyIdSetting)
        return keyId
    }

    private func get<Reply: Decodable>(_ path: String) async throws -> Reply {
        let (data, _) = try await session.data(from: server.appending(path: path))
        return try JSONDecoder().decode(Reply.self, from: data)
    }

    /// Anything thrown along the way, in words a person can act on.
    private static func failure(from error: any Error) -> StudyFailure {
        switch error {
        case let failure as StudyFailure:
            failure
        case let error as URLError where error.code == .timedOut:
            .tooSlow
        case is URLError:
            .unreachable
        default:
            StudyFailure(
                "That study couldn't be prepared right now — please tap again.",
                log: String(describing: error)
            )
        }
    }
}

extension StudyFailure {
    /// Internal only: the attested key needs replacing. Never shown; it is
    /// caught and retried, and only ever reaches a person as whatever the
    /// retry produced.
    static let keyRejected = StudyFailure(
        "The study service didn't recognise this iPhone — try again later. Your journal is unaffected.",
        log: "attested key rejected"
    )
}

private struct StudyReply: Decodable, Sendable {
    let study: Study
}

private struct PlanReply: Decodable, Sendable {
    let plan: GeneratedPlan
}

/// The reply to a request that answers with nothing but "done".
private struct NoReply: Decodable, Sendable {}

private struct ErrorReply: Decodable {
    struct Problem: Decodable {
        let message: String
        let type: String?
    }

    let error: Problem
}

private struct ChallengeReply: Decodable {
    let challenge: String
}
