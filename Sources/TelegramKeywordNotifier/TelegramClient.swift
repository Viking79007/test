import Foundation

enum TelegramClientError: LocalizedError {
    case invalidToken
    case invalidResponse
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .invalidToken:
            return "Укажите корректный токен Telegram-бота."
        case .invalidResponse:
            return "Telegram вернул неожиданный ответ."
        case .apiError(let message):
            return message
        }
    }
}

struct TelegramClient {
    let botToken: String

    func fetchUpdates(offset: Int64?, timeout: Int) async throws -> [TelegramUpdate] {
        let trimmedToken = botToken.trimmed()
        guard !trimmedToken.isEmpty else {
            throw TelegramClientError.invalidToken
        }

        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.telegram.org"
        components.path = "/bot\(trimmedToken)/getUpdates"

        var queryItems = [
            URLQueryItem(name: "timeout", value: "\(timeout)"),
            URLQueryItem(name: "allowed_updates", value: #"["message","channel_post"]"#)
        ]

        if let offset {
            queryItems.append(URLQueryItem(name: "offset", value: "\(offset)"))
        }

        components.queryItems = queryItems

        guard let url = components.url else {
            throw TelegramClientError.invalidToken
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            throw TelegramClientError.invalidResponse
        }

        let decoded = try JSONDecoder().decode(TelegramAPIResponse<[TelegramUpdate]>.self, from: data)
        guard decoded.ok else {
            throw TelegramClientError.apiError(decoded.description ?? "Telegram API вернул ошибку.")
        }

        return decoded.result ?? []
    }
}
