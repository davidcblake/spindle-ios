import AVFoundation
import Foundation
import PPInput
import Speech

/// Speaking a thought instead of typing it, behind the foundation's
/// `Transcriber` seam.
///
/// Asked for in Dave's first feedback note. **Recognition happens on the
/// phone and nowhere else** (`requiresOnDeviceRecognition`): no audio and no
/// words leave it, so the privacy answers in `docs/app-store.md` stay true. A
/// phone that cannot recognize speech on its own reports `.unavailable`, and
/// the Speak button is not shown; the keyboard's own microphone still works.
///
/// **Why Spindle has its own, on the older API.** The foundation's decision
/// `0016` plans its implementation on `SpeechAnalyzer`, which needs iOS 26,
/// and says a second one on `SFSpeechRecognizer` should exist only if an app
/// needs it. Spindle does: it runs on iOS 18, and the family and ward phones
/// it is shared with are not all on 26. Screens see only `Transcriber`, so
/// when the foundation's implementation exists this file is the only thing
/// that changes.
///
/// `@unchecked Sendable` because the one piece of shared state, the session
/// being listened to, is only ever read or written under `lock`.
final class OnDeviceTranscriber: Transcriber, @unchecked Sendable {
    private struct Session {
        let recognizer: SFSpeechRecognizer
        let engine: AVAudioEngine
        let request: SFSpeechAudioBufferRecognitionRequest
        let task: SFSpeechRecognitionTask
        let words: AsyncStream<Transcript>.Continuation
    }

    private let lock = NSLock()
    private var session: Session?

    func readiness() async -> TranscriberReadiness {
        guard let recognizer = SFSpeechRecognizer(), recognizer.supportsOnDeviceRecognition else {
            return .unavailable
        }
        return .ready
    }

    /// Nothing to fetch: on this API the on-device model comes with the
    /// phone's own dictation, or the phone reports `.unavailable`.
    func prepare() async throws {}

    func startDictation() async throws -> AsyncStream<Transcript> {
        stopDictation()

        guard await Self.speechRecognitionAllowed() else {
            throw InputFailure(
                userMessage: "Spindle needs permission to recognize speech. You can turn it on in Settings › Privacy & Security › Speech Recognition.",
                logMessage: "Speech recognition not authorized."
            )
        }
        guard await AVAudioApplication.requestRecordPermission() else {
            throw InputFailure(
                userMessage: "Spindle needs the microphone to hear you. You can turn it on in Settings › Privacy & Security › Microphone.",
                logMessage: "Microphone permission not granted."
            )
        }
        guard let recognizer = SFSpeechRecognizer(), recognizer.isAvailable, recognizer.supportsOnDeviceRecognition else {
            throw InputFailure(
                userMessage: "Speaking a thought isn't available on this iPhone right now. The microphone on the keyboard still works.",
                logMessage: "No on-device SFSpeechRecognizer for the current locale."
            )
        }

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.requiresOnDeviceRecognition = true
        request.addsPunctuation = true

        let engine = AVAudioEngine()
        do {
            let audio = AVAudioSession.sharedInstance()
            try audio.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audio.setActive(true, options: .notifyOthersOnDeactivation)
            let input = engine.inputNode
            input.installTap(onBus: 0, bufferSize: 1024, format: input.outputFormat(forBus: 0), block: Self.feeding(request))
            engine.prepare()
            try engine.start()
        } catch {
            engine.inputNode.removeTap(onBus: 0)
            throw InputFailure(
                userMessage: "The microphone couldn't start. Try again in a moment.",
                logMessage: "AVAudioEngine failed to start: \(error)"
            )
        }

        let (stream, words) = AsyncStream<Transcript>.makeStream()
        let task = recognizer.recognitionTask(with: request) { [weak self] result, error in
            if let result {
                words.yield(Transcript(text: result.bestTranscription.formattedString, isFinal: result.isFinal))
            }
            // A long pause, the system's one-minute limit, or an error all end
            // a stretch of talking.
            if error != nil || result?.isFinal == true {
                self?.stopDictation()
            }
        }
        words.onTermination = { [weak self] _ in self?.stopDictation() }
        lock.withLock {
            session = Session(recognizer: recognizer, engine: engine, request: request, task: task, words: words)
        }
        return stream
    }

    /// Closes the microphone and finishes the stream. The words already
    /// delivered are the ones kept.
    func stopDictation() {
        let ending = lock.withLock { () -> Session? in
            defer { session = nil }
            return session
        }
        guard let ending else { return }
        ending.engine.stop()
        ending.engine.inputNode.removeTap(onBus: 0)
        ending.request.endAudio()
        ending.task.finish()
        ending.words.finish()
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private static func speechRecognitionAllowed() async -> Bool {
        let status = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { continuation.resume(returning: $0) }
        }
        return status == .authorized
    }

    /// Hands each slice of microphone audio to the recognizer, on the audio
    /// thread. Apple's request takes audio from any thread, and only this tap
    /// ever feeds it.
    private static func feeding(_ request: SFSpeechAudioBufferRecognitionRequest) -> AVAudioNodeTapBlock {
        nonisolated(unsafe) let request = request
        return { buffer, _ in request.append(buffer) }
    }
}

/// Where spoken words go in the text box.
enum SpokenThought {
    /// What was typed, then what was heard, with one space between.
    static func joined(_ typed: String, _ heard: String) -> String {
        let spoken = heard.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !spoken.isEmpty else { return typed }
        guard !typed.isEmpty else { return spoken }
        return typed.hasSuffix(" ") || typed.hasSuffix("\n") ? typed + spoken : typed + " " + spoken
    }
}
