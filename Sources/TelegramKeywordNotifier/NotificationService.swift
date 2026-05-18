import Foundation
import UserNotifications

enum NotificationService {
    static func requestAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
                continuation.resume(returning: granted)
            }
        }
    }

    static func sendNotification(for match: MatchedTelegramMessage) async throws {
        let content = UNMutableNotificationContent()
        content.title = "Telegram: \(match.keyword)"
        content.subtitle = "\(match.chatName) - \(match.senderName)"
        content.body = match.text.shortened(to: 220)
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "telegram-keyword-\(match.id)-\(match.keyword)",
            content: content,
            trigger: nil
        )

        try await UNUserNotificationCenter.current().add(request)
    }
}

extension String {
    func shortened(to limit: Int) -> String {
        guard count > limit else {
            return self
        }

        let endIndex = index(startIndex, offsetBy: max(0, limit - 1))
        return String(self[..<endIndex]) + "..."
    }
}
