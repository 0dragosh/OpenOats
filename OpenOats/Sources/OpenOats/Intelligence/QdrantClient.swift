import Foundation

/// Minimal client for searching vectors from a Qdrant collection.
actor QdrantClient {
    enum QdrantError: Error, LocalizedError {
        case invalidURL
        case httpError(Int, String)
        case decodingError

        var errorDescription: String? {
            switch self {
            case .invalidURL: "Invalid Qdrant URL"
            case .httpError(let code, let msg): "Qdrant error (HTTP \(code)): \(msg)"
            case .decodingError: "Failed to decode Qdrant response"
            }
        }
    }

    func search(
        baseURL: String,
        collection: String,
        apiKey: String,
        vector: [Float],
        limit: Int
    ) async throws -> [KBResult] {
        let trimmed = baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let url = URL(string: "\(trimmed)/collections/\(collection.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? collection)/points/search") else {
            throw QdrantError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if !apiKey.isEmpty {
            request.setValue(apiKey, forHTTPHeaderField: "api-key")
        }
        request.httpBody = try JSONEncoder().encode(SearchRequest(
            vector: vector,
            limit: limit,
            with_payload: true,
            with_vector: false
        ))

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw QdrantError.httpError(-1, "No HTTP response")
        }

        guard (200...299).contains(http.statusCode) else {
            let msg = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw QdrantError.httpError(http.statusCode, msg)
        }

        let decoded: SearchResponse
        do {
            decoded = try JSONDecoder().decode(SearchResponse.self, from: data)
        } catch {
            throw QdrantError.decodingError
        }

        return decoded.result.map { item in
            let text = payloadString(item.payload, keys: ["text", "content", "chunk", "body"])
            let source = payloadString(item.payload, keys: ["sourceFile", "source", "file", "path"])
            let header = payloadString(item.payload, keys: ["headerContext", "header", "section", "title"])
            return KBResult(
                text: text,
                sourceFile: source.isEmpty ? collection : source,
                headerContext: header,
                score: item.score
            )
        }
    }

    private nonisolated func payloadString(_ payload: [String: JSONValue], keys: [String]) -> String {
        for key in keys {
            if case .string(let value) = payload[key] {
                return value
            }
        }
        return ""
    }

    private struct SearchRequest: Encodable {
        let vector: [Float]
        let limit: Int
        let with_payload: Bool
        let with_vector: Bool
    }

    private struct SearchResponse: Decodable {
        let result: [SearchResult]

        struct SearchResult: Decodable {
            let score: Double
            let payload: [String: JSONValue]
        }
    }

    private enum JSONValue: Decodable {
        case string(String)
        case number(Double)
        case bool(Bool)
        case array([JSONValue])
        case object([String: JSONValue])
        case null

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if container.decodeNil() {
                self = .null
            } else if let value = try? container.decode(String.self) {
                self = .string(value)
            } else if let value = try? container.decode(Double.self) {
                self = .number(value)
            } else if let value = try? container.decode(Bool.self) {
                self = .bool(value)
            } else if let value = try? container.decode([JSONValue].self) {
                self = .array(value)
            } else if let value = try? container.decode([String: JSONValue].self) {
                self = .object(value)
            } else {
                throw DecodingError.typeMismatch(
                    JSONValue.self,
                    DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unsupported JSON value")
                )
            }
        }
    }
}
