import Foundation

/// Uses an OpenAI-compatible chat completions endpoint to rerank candidate documents.
actor OpenAIRerankClient {
    enum RerankError: Error, LocalizedError {
        case invalidURL
        case httpError(Int, String)
        case emptyChoices
        case invalidResponse

        var errorDescription: String? {
            switch self {
            case .invalidURL: "Invalid OpenAI rerank URL"
            case .httpError(let code, let msg): "OpenAI rerank error (HTTP \(code)): \(msg)"
            case .emptyChoices: "No completion choices returned"
            case .invalidResponse: "Invalid reranking response"
            }
        }
    }

    func rerank(
        baseURL: String,
        apiKey: String,
        model: String,
        query: String,
        documents: [String],
        topN: Int
    ) async throws -> [(index: Int, score: Double)] {
        let trimmed = baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let url = URL(string: "\(trimmed)/v1/chat/completions") else {
            throw RerankError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if !apiKey.isEmpty {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }

        let docsBlob = documents.enumerated().map { idx, doc in
            "[\(idx)] \(doc)"
        }.joined(separator: "\n\n")

        let systemPrompt = """
        You are a reranking engine. Return strict JSON only.
        Score each document from 0 to 1 based on relevance to the query.
        JSON schema: {"results":[{"index":0,"score":0.0}]}
        Include only indexes that were provided.
        """

        let userPrompt = """
        Query:
        \(query)

        Documents:
        \(docsBlob)

        Return the top \(max(1, topN)) documents by score in descending order.
        """

        let payload = ChatRequest(
            model: model,
            messages: [
                .init(role: "system", content: systemPrompt),
                .init(role: "user", content: userPrompt)
            ],
            temperature: 0
        )

        request.httpBody = try JSONEncoder().encode(payload)
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw RerankError.httpError(-1, "No HTTP response")
        }

        guard (200...299).contains(http.statusCode) else {
            let msg = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw RerankError.httpError(http.statusCode, msg)
        }

        let completion = try JSONDecoder().decode(ChatResponse.self, from: data)
        guard let content = completion.choices.first?.message.content else {
            throw RerankError.emptyChoices
        }

        guard let jsonData = extractJSON(content).data(using: .utf8) else {
            throw RerankError.invalidResponse
        }

        let decoded = try JSONDecoder().decode(RerankResponse.self, from: jsonData)
        let valid = decoded.results
            .filter { $0.index >= 0 && $0.index < documents.count }
            .sorted { $0.score > $1.score }
        return Array(valid.prefix(max(1, topN))).map { ($0.index, $0.score) }
    }

    private nonisolated func extractJSON(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("```") {
            let lines = trimmed.components(separatedBy: .newlines)
            let body = lines.dropFirst().dropLast()
            return body.joined(separator: "\n")
        }
        return trimmed
    }

    private struct ChatRequest: Encodable {
        struct Message: Encodable {
            let role: String
            let content: String
        }

        let model: String
        let messages: [Message]
        let temperature: Double
    }

    private struct ChatResponse: Decodable {
        struct Choice: Decodable {
            struct Message: Decodable {
                let content: String
            }

            let message: Message
        }

        let choices: [Choice]
    }

    private struct RerankResponse: Decodable {
        struct Item: Decodable {
            let index: Int
            let score: Double
        }

        let results: [Item]
    }
}
