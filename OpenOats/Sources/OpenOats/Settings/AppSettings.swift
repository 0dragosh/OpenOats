import AppKit
import Foundation
import Observation
import Security
import CoreAudio

enum LLMProvider: String, CaseIterable, Identifiable {
    case openRouter
    case ollama
    case customOpenAI

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .openRouter: "OpenRouter"
        case .ollama: "Ollama"
        case .customOpenAI: "Custom OpenAI API"
        }
    }
}

enum TranscriptionModel: String, CaseIterable, Identifiable {
    case parakeetV2
    case parakeetV3
    case qwen3ASR06B
    case customOpenAISTT

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .parakeetV2: "Parakeet TDT v2"
        case .parakeetV3: "Parakeet TDT v3"
        case .qwen3ASR06B: "Qwen3 ASR 0.6B"
        case .customOpenAISTT: "Custom OpenAI STT"
        }
    }

    var downloadPrompt: String {
        switch self {
        case .parakeetV2, .parakeetV3:
            "Transcription requires a one-time model download."
        case .qwen3ASR06B:
            "Qwen3 ASR requires a one-time model download."
        case .customOpenAISTT:
            "Custom OpenAI STT runs remotely and does not require local model download."
        }
    }

    var supportsExplicitLanguageHint: Bool {
        switch self {
        case .qwen3ASR06B, .customOpenAISTT:
            true
        case .parakeetV2, .parakeetV3:
            false
        }
    }

    var localeFieldTitle: String {
        switch self {
        case .qwen3ASR06B:
            "Language Hint"
        case .customOpenAISTT, .parakeetV2, .parakeetV3:
            "Locale"
        }
    }

    var localeHelpText: String {
        switch self {
        case .parakeetV2:
            "Parakeet TDT v2 is English-only. Locale changes do not affect this model."
        case .parakeetV3:
            "Parakeet TDT v3 auto-detects among its supported languages. Locale changes do not affect this model."
        case .qwen3ASR06B:
            "Optional. Used as a language hint for Qwen3 ASR. Enter a locale such as en-US, fr-FR, or ja-JP. Applies when a new session starts."
        case .customOpenAISTT:
            "Optional. Sent as the transcription language hint to your OpenAI-compatible STT endpoint when supported."
        }
    }
}

enum EmbeddingProvider: String, CaseIterable, Identifiable {
    case voyageAI
    case ollama
    case openAICompatible

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .voyageAI: "Voyage AI"
        case .ollama: "Ollama"
        case .openAICompatible: "OpenAI Compatible"
        }
    }
}

enum KnowledgeBaseBackend: String, CaseIterable, Identifiable {
    case markdownFiles
    case qdrant

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .markdownFiles: "Markdown/TXT Folder"
        case .qdrant: "Qdrant Vector DB"
        }
    }
}

@Observable
@MainActor
final class AppSettings {
    var kbFolderPath: String {
        didSet { UserDefaults.standard.set(kbFolderPath, forKey: "kbFolderPath") }
    }

    var notesFolderPath: String {
        didSet { UserDefaults.standard.set(notesFolderPath, forKey: "notesFolderPath") }
    }

    var selectedModel: String {
        didSet { UserDefaults.standard.set(selectedModel, forKey: "selectedModel") }
    }

    var transcriptionLocale: String {
        didSet { UserDefaults.standard.set(transcriptionLocale, forKey: "transcriptionLocale") }
    }

    var transcriptionModel: TranscriptionModel {
        didSet { UserDefaults.standard.set(transcriptionModel.rawValue, forKey: "transcriptionModel") }
    }

    /// Stored as the AudioDeviceID integer. 0 means "use system default".
    var inputDeviceID: AudioDeviceID {
        didSet { UserDefaults.standard.set(Int(inputDeviceID), forKey: "inputDeviceID") }
    }

    var openRouterApiKey: String {
        didSet { KeychainHelper.save(key: "openRouterApiKey", value: openRouterApiKey) }
    }

    var customOpenAIBaseURL: String {
        didSet { UserDefaults.standard.set(customOpenAIBaseURL, forKey: "customOpenAIBaseURL") }
    }

    var customOpenAIApiKey: String {
        didSet { KeychainHelper.save(key: "customOpenAIApiKey", value: customOpenAIApiKey) }
    }

    var customOpenAICompletionModel: String {
        didSet { UserDefaults.standard.set(customOpenAICompletionModel, forKey: "customOpenAICompletionModel") }
    }

    var customOpenAIEmbeddingModel: String {
        didSet { UserDefaults.standard.set(customOpenAIEmbeddingModel, forKey: "customOpenAIEmbeddingModel") }
    }

    var customOpenAITranscriptionModel: String {
        didSet { UserDefaults.standard.set(customOpenAITranscriptionModel, forKey: "customOpenAITranscriptionModel") }
    }

    var voyageApiKey: String {
        didSet { KeychainHelper.save(key: "voyageApiKey", value: voyageApiKey) }
    }

    var llmProvider: LLMProvider {
        didSet { UserDefaults.standard.set(llmProvider.rawValue, forKey: "llmProvider") }
    }

    var embeddingProvider: EmbeddingProvider {
        didSet { UserDefaults.standard.set(embeddingProvider.rawValue, forKey: "embeddingProvider") }
    }

    var knowledgeBaseBackend: KnowledgeBaseBackend {
        didSet { UserDefaults.standard.set(knowledgeBaseBackend.rawValue, forKey: "knowledgeBaseBackend") }
    }

    var qdrantBaseURL: String {
        didSet { UserDefaults.standard.set(qdrantBaseURL, forKey: "qdrantBaseURL") }
    }

    var qdrantCollection: String {
        didSet { UserDefaults.standard.set(qdrantCollection, forKey: "qdrantCollection") }
    }

    var qdrantApiKey: String {
        didSet { KeychainHelper.save(key: "qdrantApiKey", value: qdrantApiKey) }
    }

    var openAIRerankEnabled: Bool {
        didSet { UserDefaults.standard.set(openAIRerankEnabled, forKey: "openAIRerankEnabled") }
    }

    var openAIRerankBaseURL: String {
        didSet { UserDefaults.standard.set(openAIRerankBaseURL, forKey: "openAIRerankBaseURL") }
    }

    var openAIRerankApiKey: String {
        didSet { KeychainHelper.save(key: "openAIRerankApiKey", value: openAIRerankApiKey) }
    }

    var openAIRerankModel: String {
        didSet { UserDefaults.standard.set(openAIRerankModel, forKey: "openAIRerankModel") }
    }

    var ollamaBaseURL: String {
        didSet { UserDefaults.standard.set(ollamaBaseURL, forKey: "ollamaBaseURL") }
    }

    var ollamaLLMModel: String {
        didSet { UserDefaults.standard.set(ollamaLLMModel, forKey: "ollamaLLMModel") }
    }

    var ollamaEmbedModel: String {
        didSet { UserDefaults.standard.set(ollamaEmbedModel, forKey: "ollamaEmbedModel") }
    }

    var openAIEmbedBaseURL: String {
        didSet { UserDefaults.standard.set(openAIEmbedBaseURL, forKey: "openAIEmbedBaseURL") }
    }

    var openAIEmbedApiKey: String {
        didSet { KeychainHelper.save(key: "openAIEmbedApiKey", value: openAIEmbedApiKey) }
    }

    var openAIEmbedModel: String {
        didSet { UserDefaults.standard.set(openAIEmbedModel, forKey: "openAIEmbedModel") }
    }

    /// Whether the user has acknowledged their obligation to comply with recording consent laws.
    var hasAcknowledgedRecordingConsent: Bool {
        didSet { UserDefaults.standard.set(hasAcknowledgedRecordingConsent, forKey: "hasAcknowledgedRecordingConsent") }
    }

    /// When true, all app windows are invisible to screen sharing / recording.
    var hideFromScreenShare: Bool {
        didSet {
            UserDefaults.standard.set(hideFromScreenShare, forKey: "hideFromScreenShare")
            applyScreenShareVisibility()
        }
    }

    init() {
        let defaults = UserDefaults.standard

        // One-time migrations from previous bundle IDs
        Self.migrateFromOldBundleIfNeeded(defaults: defaults)
        Self.migrateFromOpenGranolaIfNeeded(defaults: defaults)

        self.kbFolderPath = defaults.string(forKey: "kbFolderPath") ?? ""

        let defaultNotesPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Documents/OpenOats").path
        self.notesFolderPath = defaults.string(forKey: "notesFolderPath") ?? defaultNotesPath
        self.selectedModel = defaults.string(forKey: "selectedModel") ?? "google/gemini-3-flash-preview"
        self.transcriptionLocale = defaults.string(forKey: "transcriptionLocale") ?? "en-US"
        self.transcriptionModel = TranscriptionModel(
            rawValue: defaults.string(forKey: "transcriptionModel") ?? ""
        ) ?? .parakeetV2
        self.inputDeviceID = AudioDeviceID(defaults.integer(forKey: "inputDeviceID"))
        let customOpenAIApiKey = KeychainHelper.load(key: "customOpenAIApiKey") ?? ""
        let customOpenAIEmbeddingModel = defaults.string(forKey: "customOpenAIEmbeddingModel") ?? "text-embedding-3-small"

        self.openRouterApiKey = KeychainHelper.load(key: "openRouterApiKey") ?? ""
        self.customOpenAIBaseURL = defaults.string(forKey: "customOpenAIBaseURL") ?? "https://api.openai.com"
        self.customOpenAIApiKey = customOpenAIApiKey
        self.customOpenAICompletionModel = defaults.string(forKey: "customOpenAICompletionModel") ?? "gpt-4o-mini"
        self.customOpenAIEmbeddingModel = customOpenAIEmbeddingModel
        self.customOpenAITranscriptionModel = defaults.string(forKey: "customOpenAITranscriptionModel") ?? "gpt-4o-transcribe"
        self.voyageApiKey = KeychainHelper.load(key: "voyageApiKey") ?? ""
        self.llmProvider = LLMProvider(rawValue: defaults.string(forKey: "llmProvider") ?? "") ?? .openRouter
        self.embeddingProvider = EmbeddingProvider(rawValue: defaults.string(forKey: "embeddingProvider") ?? "") ?? .voyageAI
        self.knowledgeBaseBackend = KnowledgeBaseBackend(
            rawValue: defaults.string(forKey: "knowledgeBaseBackend") ?? ""
        ) ?? .markdownFiles
        self.qdrantBaseURL = defaults.string(forKey: "qdrantBaseURL") ?? "http://localhost:6333"
        self.qdrantCollection = defaults.string(forKey: "qdrantCollection") ?? ""
        self.qdrantApiKey = KeychainHelper.load(key: "qdrantApiKey") ?? ""
        self.openAIRerankEnabled = defaults.object(forKey: "openAIRerankEnabled") == nil
            ? false
            : defaults.bool(forKey: "openAIRerankEnabled")
        self.openAIRerankBaseURL = defaults.string(forKey: "openAIRerankBaseURL") ?? self.customOpenAIBaseURL
        self.openAIRerankApiKey = KeychainHelper.load(key: "openAIRerankApiKey") ?? self.customOpenAIApiKey
        self.openAIRerankModel = defaults.string(forKey: "openAIRerankModel") ?? "gpt-4o-mini"
        self.ollamaBaseURL = defaults.string(forKey: "ollamaBaseURL") ?? "http://localhost:11434"
        self.ollamaLLMModel = defaults.string(forKey: "ollamaLLMModel") ?? "qwen3:8b"
        self.ollamaEmbedModel = defaults.string(forKey: "ollamaEmbedModel") ?? "nomic-embed-text"
        self.openAIEmbedBaseURL = defaults.string(forKey: "openAIEmbedBaseURL") ?? "http://localhost:8080"
        self.openAIEmbedApiKey = KeychainHelper.load(key: "openAIEmbedApiKey") ?? customOpenAIApiKey
        self.openAIEmbedModel = defaults.string(forKey: "openAIEmbedModel") ?? customOpenAIEmbeddingModel
        self.hasAcknowledgedRecordingConsent = defaults.bool(forKey: "hasAcknowledgedRecordingConsent")

        // Default to true (hidden) if key has never been set
        if defaults.object(forKey: "hideFromScreenShare") == nil {
            self.hideFromScreenShare = true
        } else {
            self.hideFromScreenShare = defaults.bool(forKey: "hideFromScreenShare")
        }

        // Ensure notes folder exists
        try? FileManager.default.createDirectory(
            atPath: notesFolderPath,
            withIntermediateDirectories: true
        )
    }

    /// Migrate settings from the old "On The Spot" (com.onthespot.app) bundle.
    /// Copies UserDefaults and Keychain entries to the current bundle, then marks migration as done.
    private static func migrateFromOldBundleIfNeeded(defaults: UserDefaults) {
        let migrationKey = "didMigrateFromOnTheSpot"
        guard !defaults.bool(forKey: migrationKey) else { return }
        defer { defaults.set(true, forKey: migrationKey) }

        guard let oldDefaults = UserDefaults(suiteName: "com.onthespot.app") else { return }

        let keysToMigrate = [
            "kbFolderPath", "notesFolderPath", "selectedModel", "transcriptionLocale", "transcriptionModel", "inputDeviceID",
            "llmProvider", "embeddingProvider", "knowledgeBaseBackend",
            "qdrantBaseURL", "qdrantCollection",
            "openAIRerankEnabled", "openAIRerankBaseURL", "openAIRerankModel",
            "ollamaBaseURL", "ollamaLLMModel", "ollamaEmbedModel",
            "openAIEmbedBaseURL", "openAIEmbedModel",
            "hideFromScreenShare", "isTranscriptExpanded", "hasCompletedOnboarding", "hasAcknowledgedRecordingConsent"
        ]
        for key in keysToMigrate {
            if let value = oldDefaults.object(forKey: key), defaults.object(forKey: key) == nil {
                defaults.set(value, forKey: key)
            }
        }

        let oldService = "com.onthespot.app"
        let keychainKeys = ["openRouterApiKey", "voyageApiKey", "qdrantApiKey", "openAIRerankApiKey", "openAIEmbedApiKey"]
        for key in keychainKeys {
            if KeychainHelper.load(key: key) == nil,
               let oldValue = Self.loadKeychain(service: oldService, key: key) {
                KeychainHelper.save(key: key, value: oldValue)
            }
        }
    }

    /// Migrate settings from the previous "OpenGranola" (com.opengranola.app) bundle.
    private static func migrateFromOpenGranolaIfNeeded(defaults: UserDefaults) {
        let migrationKey = "didMigrateFromOpenGranola"
        guard !defaults.bool(forKey: migrationKey) else { return }
        defer { defaults.set(true, forKey: migrationKey) }

        guard let oldDefaults = UserDefaults(suiteName: "com.opengranola.app") else {
            migrateFilesFromOpenGranola(defaults: defaults)
            return
        }

        let keysToMigrate = [
            "kbFolderPath", "notesFolderPath", "selectedModel", "transcriptionLocale", "transcriptionModel", "inputDeviceID",
            "llmProvider", "embeddingProvider", "knowledgeBaseBackend",
            "qdrantBaseURL", "qdrantCollection",
            "openAIRerankEnabled", "openAIRerankBaseURL", "openAIRerankModel",
            "ollamaBaseURL", "ollamaLLMModel", "ollamaEmbedModel",
            "openAIEmbedBaseURL", "openAIEmbedModel",
            "hideFromScreenShare", "isTranscriptExpanded", "hasCompletedOnboarding", "hasAcknowledgedRecordingConsent"
        ]
        for key in keysToMigrate {
            if let value = oldDefaults.object(forKey: key), defaults.object(forKey: key) == nil {
                defaults.set(value, forKey: key)
            }
        }

        let oldService = "com.opengranola.app"
        let keychainKeys = ["openRouterApiKey", "voyageApiKey", "customOpenAIApiKey", "qdrantApiKey", "openAIRerankApiKey", "openAIEmbedApiKey"]
        for key in keychainKeys {
            if KeychainHelper.load(key: key) == nil,
               let oldValue = Self.loadKeychain(service: oldService, key: key) {
                KeychainHelper.save(key: key, value: oldValue)
            }
        }

        migrateFilesFromOpenGranola(defaults: defaults)
    }

    /// Migrate file-backed state (sessions, templates, KB cache, transcripts)
    /// from ~/Library/Application Support/OpenGranola/ to OpenOats/ and
    /// handle the implicit KB folder default.
    private static func migrateFilesFromOpenGranola(defaults: UserDefaults) {
        let fm = FileManager.default
        let home = fm.homeDirectoryForCurrentUser
        let appSupport = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!

        let oldAppSupportDir = appSupport.appendingPathComponent("OpenGranola")
        let newAppSupportDir = appSupport.appendingPathComponent("OpenOats")

        if fm.fileExists(atPath: oldAppSupportDir.path) {
            try? fm.createDirectory(at: newAppSupportDir, withIntermediateDirectories: true)

            let oldSessions = oldAppSupportDir.appendingPathComponent("sessions")
            let newSessions = newAppSupportDir.appendingPathComponent("sessions")
            if fm.fileExists(atPath: oldSessions.path) && !fm.fileExists(atPath: newSessions.path) {
                try? fm.moveItem(at: oldSessions, to: newSessions)
            }

            let oldTemplates = oldAppSupportDir.appendingPathComponent("templates.json")
            let newTemplates = newAppSupportDir.appendingPathComponent("templates.json")
            if fm.fileExists(atPath: oldTemplates.path) && !fm.fileExists(atPath: newTemplates.path) {
                try? fm.moveItem(at: oldTemplates, to: newTemplates)
            }

            let oldCache = oldAppSupportDir.appendingPathComponent("kb_cache.json")
            let newCache = newAppSupportDir.appendingPathComponent("kb_cache.json")
            if fm.fileExists(atPath: oldCache.path) && !fm.fileExists(atPath: newCache.path) {
                try? fm.moveItem(at: oldCache, to: newCache)
            }
        }

        let oldDocDir = home.appendingPathComponent("Documents/OpenGranola")
        let newDocDir = home.appendingPathComponent("Documents/OpenOats")

        if defaults.string(forKey: "notesFolderPath") == nil {
            if fm.fileExists(atPath: oldDocDir.path) {
                let contents = (try? fm.contentsOfDirectory(atPath: oldDocDir.path)) ?? []
                if !contents.isEmpty {
                    defaults.set(oldDocDir.path, forKey: "notesFolderPath")
                }
            }
        }

        let activeKB = defaults.string(forKey: "kbFolderPath") ?? ""
        let activeNotes = defaults.string(forKey: "notesFolderPath") ?? ""
        if fm.fileExists(atPath: oldDocDir.path) && oldDocDir.path != activeKB && oldDocDir.path != activeNotes {
            try? fm.createDirectory(at: newDocDir, withIntermediateDirectories: true)
            if let files = try? fm.contentsOfDirectory(at: oldDocDir, includingPropertiesForKeys: nil) {
                for file in files where file.pathExtension == "txt" {
                    let dest = newDocDir.appendingPathComponent(file.lastPathComponent)
                    if !fm.fileExists(atPath: dest.path) {
                        try? fm.moveItem(at: file, to: dest)
                    }
                }
            }
        }
    }

    /// Read a keychain entry from a specific service (used for migration only).
    private static func loadKeychain(service: String, key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// Apply current screen-share visibility to all app windows.
    func applyScreenShareVisibility() {
        let type: NSWindow.SharingType = hideFromScreenShare ? .none : .readOnly
        for window in NSApp.windows {
            window.sharingType = type
        }
    }

    var kbFolderURL: URL? {
        guard !kbFolderPath.isEmpty else { return nil }
        return URL(fileURLWithPath: kbFolderPath)
    }

    var locale: Locale {
        Locale(identifier: transcriptionLocale)
    }

    var transcriptionModelDisplay: String {
        transcriptionModel.displayName
    }

    /// The model name to display in the UI, respecting the active LLM provider.
    var activeModelDisplay: String {
        let raw: String
        switch llmProvider {
        case .openRouter: raw = selectedModel
        case .ollama: raw = ollamaLLMModel
        case .customOpenAI: raw = customOpenAICompletionModel
        }
        return raw.split(separator: "/").last.map(String.init) ?? raw
    }
}

// MARK: - Keychain Helper

enum KeychainHelper {
    private static let service = "com.opengranola.app"

    static func save(key: String, value: String) {
        guard let data = value.data(using: .utf8) else { return }
        delete(key: key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
        ]

        SecItemAdd(query as CFDictionary, nil)
    }

    static func load(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]
        SecItemDelete(query as CFDictionary)
    }
}
