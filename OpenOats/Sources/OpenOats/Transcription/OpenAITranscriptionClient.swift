import AVFoundation
import Foundation

actor OpenAITranscriptionClient {
    enum ClientError: Error, LocalizedError {
        case invalidBaseURL
        case encodingFailed
        case httpError(Int, String)
        case missingTranscript

        var errorDescription: String? {
            switch self {
            case .invalidBaseURL:
                return "Invalid OpenAI-compatible base URL"
            case .encodingFailed:
                return "Failed to encode audio for transcription"
            case .httpError(let code, let body):
                return "OpenAI-compatible transcription error (HTTP \(code)): \(body)"
            case .missingTranscript:
                return "OpenAI-compatible transcription response did not contain text"
            }
        }
    }

    func transcribe(
        samples: [Float],
        baseURL: String,
        apiKey: String,
        model: String,
        language: String?
    ) async throws -> String {
        guard !apiKey.isEmpty else { throw ClientError.httpError(401, "Missing API key") }
        guard let endpoint = URL(string: baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/")) + "/v1/audio/transcriptions") else {
            throw ClientError.invalidBaseURL
        }

        let wavData = makeWAV(samples: samples, sampleRate: 16_000)
        guard !wavData.isEmpty else { throw ClientError.encodingFailed }

        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = makeMultipartBody(
            boundary: boundary,
            audioData: wavData,
            model: model,
            language: language
        )

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw ClientError.httpError(-1, "No HTTP response")
        }

        guard (200...299).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw ClientError.httpError(http.statusCode, body)
        }

        let decoded = try JSONDecoder().decode(TranscriptionResponse.self, from: data)
        let text = decoded.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { throw ClientError.missingTranscript }
        return text
    }

    private func makeMultipartBody(
        boundary: String,
        audioData: Data,
        model: String,
        language: String?
    ) -> Data {
        var data = Data()

        func append(_ string: String) {
            data.append(string.data(using: .utf8)!)
        }

        append("--\(boundary)\r\n")
        append("Content-Disposition: form-data; name=\"model\"\r\n\r\n")
        append("\(model)\r\n")

        if let language, !language.isEmpty {
            append("--\(boundary)\r\n")
            append("Content-Disposition: form-data; name=\"language\"\r\n\r\n")
            append("\(language)\r\n")
        }

        append("--\(boundary)\r\n")
        append("Content-Disposition: form-data; name=\"response_format\"\r\n\r\n")
        append("json\r\n")

        append("--\(boundary)\r\n")
        append("Content-Disposition: form-data; name=\"file\"; filename=\"audio.wav\"\r\n")
        append("Content-Type: audio/wav\r\n\r\n")
        data.append(audioData)
        append("\r\n")

        append("--\(boundary)--\r\n")
        return data
    }

    private func makeWAV(samples: [Float], sampleRate: Int) -> Data {
        let channels: UInt16 = 1
        let bitsPerSample: UInt16 = 16
        let byteRate = UInt32(sampleRate) * UInt32(channels) * UInt32(bitsPerSample / 8)
        let blockAlign = channels * bitsPerSample / 8

        var pcm = Data(capacity: samples.count * 2)
        for sample in samples {
            let clamped = max(-1.0, min(1.0, sample))
            let int16Sample = Int16(clamped * Float(Int16.max))
            var le = int16Sample.littleEndian
            pcm.append(Data(bytes: &le, count: MemoryLayout<Int16>.size))
        }

        let dataChunkSize = UInt32(pcm.count)
        let riffChunkSize = 36 + dataChunkSize

        var wav = Data()
        wav.append("RIFF".data(using: .ascii)!)
        wav.append(contentsOf: withUnsafeBytes(of: riffChunkSize.littleEndian, Array.init))
        wav.append("WAVE".data(using: .ascii)!)

        wav.append("fmt ".data(using: .ascii)!)
        wav.append(contentsOf: withUnsafeBytes(of: UInt32(16).littleEndian, Array.init))
        wav.append(contentsOf: withUnsafeBytes(of: UInt16(1).littleEndian, Array.init))
        wav.append(contentsOf: withUnsafeBytes(of: channels.littleEndian, Array.init))
        wav.append(contentsOf: withUnsafeBytes(of: UInt32(sampleRate).littleEndian, Array.init))
        wav.append(contentsOf: withUnsafeBytes(of: byteRate.littleEndian, Array.init))
        wav.append(contentsOf: withUnsafeBytes(of: blockAlign.littleEndian, Array.init))
        wav.append(contentsOf: withUnsafeBytes(of: bitsPerSample.littleEndian, Array.init))

        wav.append("data".data(using: .ascii)!)
        wav.append(contentsOf: withUnsafeBytes(of: dataChunkSize.littleEndian, Array.init))
        wav.append(pcm)

        return wav
    }

    private struct TranscriptionResponse: Decodable {
        let text: String
    }
}
