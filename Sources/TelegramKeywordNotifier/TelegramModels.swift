import Foundation

struct TelegramAPIResponse<Result: Decodable>: Decodable {
    let ok: Bool
    let result: Result?
    let description: String?
}

struct TelegramUpdate: Decodable, Identifiable {
    let updateID: Int64
    let message: TelegramMessage?
    let channelPost: TelegramMessage?

    var id: Int64 { updateID }

    var displayMessage: TelegramMessage? {
        message ?? channelPost
    }

    enum CodingKeys: String, CodingKey {
        case updateID = "update_id"
        case message
        case channelPost = "channel_post"
    }
}

struct TelegramMessage: Decodable {
    let messageID: Int64
    let date: Int64
    let chat: TelegramChat
    let from: TelegramUser?
    let senderChat: TelegramChat?
    let text: String?
    let caption: String?

    var searchableText: String? {
        text ?? caption
    }

    var senderName: String {
        if let from {
            return [from.firstName, from.lastName]
                .compactMap { $0 }
                .joined(separator: " ")
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .nonEmpty ?? from.username.map { "@\($0)" } ?? "Telegram"
        }

        return senderChat?.displayName ?? "Telegram"
    }

    enum CodingKeys: String, CodingKey {
        case messageID = "message_id"
        case date
        case chat
        case from
        case senderChat = "sender_chat"
        case text
        case caption
    }
}

struct TelegramChat: Decodable {
    let id: Int64
    let type: String?
    let title: String?
    let username: String?
    let firstName: String?
    let lastName: String?

    var displayName: String {
        title
            ?? [firstName, lastName].compactMap { $0 }.joined(separator: " ").nonEmpty
            ?? username.map { "@\($0)" }
            ?? "\(id)"
    }

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case title
        case username
        case firstName = "first_name"
        case lastName = "last_name"
    }
}

struct TelegramUser: Decodable {
    let id: Int64
    let isBot: Bool?
    let firstName: String?
    let lastName: String?
    let username: String?

    enum CodingKeys: String, CodingKey {
        case id
        case isBot = "is_bot"
        case firstName = "first_name"
        case lastName = "last_name"
        case username
    }
}

struct MatchedTelegramMessage: Identifiable {
    let id: Int64
    let chatName: String
    let senderName: String
    let text: String
    let keyword: String
    let receivedAt: Date
}

extension String {
    var nonEmpty: String? {
        isEmpty ? nil : self
    }

    func trimmed() -> String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
