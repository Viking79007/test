import Combine
import Foundation

@MainActor
final class TelegramMonitor: ObservableObject {
    @Published private(set) var isRunning = false
    @Published private(set) var statusText = "Остановлено"
    @Published private(set) var logEntries: [String] = []
    @Published private(set) var lastMatch: MatchedTelegramMessage?

    private let settings: AppSettings
    private var pollingTask: Task<Void, Never>?

    init(settings: AppSettings) {
        self.settings = settings
    }

    deinit {
        pollingTask?.cancel()
    }

    func start() {
        guard !isRunning else {
            return
        }

        let token = settings.botToken.trimmed()
        guard !token.isEmpty else {
            setError("Добавьте токен Telegram-бота.")
            return
        }

        guard !settings.keywords.isEmpty else {
            setError("Добавьте хотя бы одно ключевое слово.")
            return
        }

        pollingTask = Task { [weak self] in
            guard let self else {
                return
            }

            await self.pollLoop()
        }
    }

    func stop() {
        pollingTask?.cancel()
        pollingTask = nil
        isRunning = false
        statusText = "Остановлено"
        appendLog("Мониторинг остановлен.")
    }

    func requestNotificationPermission() {
        Task {
            let granted = await NotificationService.requestAuthorization()
            if granted {
                appendLog("Разрешение на уведомления получено.")
            } else {
                setError("macOS не разрешила отправлять уведомления.")
            }
        }
    }

    private func pollLoop() async {
        isRunning = true
        statusText = "Подключение к Telegram..."
        appendLog("Мониторинг запущен.")

        let client = TelegramClient(botToken: settings.botToken)
        var nextOffset = settings.lastUpdateID.map { $0 + 1 }

        do {
            if settings.ignoreBacklogOnStart {
                nextOffset = try await latestOffset(client: client) ?? nextOffset
            }

            statusText = "Ожидание сообщений..."

            while !Task.isCancelled {
                let updates = try await client.fetchUpdates(offset: nextOffset, timeout: 20)

                for update in updates {
                    nextOffset = max(nextOffset ?? 0, update.updateID + 1)
                    settings.lastUpdateID = update.updateID
                    await handle(update: update)
                }

                if updates.isEmpty {
                    statusText = "Ожидание сообщений..."
                }

                let sleepSeconds = min(max(settings.pollingInterval, 1), 120)
                try await Task.sleep(nanoseconds: UInt64(sleepSeconds * 1_000_000_000))
            }
        } catch is CancellationError {
            statusText = "Остановлено"
        } catch {
            setError(error.localizedDescription)
        }

        if Task.isCancelled {
            statusText = "Остановлено"
        }

        isRunning = false
    }

    private func latestOffset(client: TelegramClient) async throws -> Int64? {
        var offset: Int64?
        var latestUpdateID: Int64?

        repeat {
            let updates = try await client.fetchUpdates(offset: offset, timeout: 0)
            guard let batchLatest = updates.map(\.updateID).max() else {
                break
            }

            latestUpdateID = batchLatest
            offset = batchLatest + 1
        } while !Task.isCancelled

        guard let latestUpdateID else {
            return nil
        }

        settings.lastUpdateID = latestUpdateID
        appendLog("Старые сообщения пропущены до update_id \(latestUpdateID).")
        return latestUpdateID + 1
    }

    private func handle(update: TelegramUpdate) async {
        guard let message = update.displayMessage, let text = message.searchableText else {
            return
        }

        guard matchesChatFilter(message.chat) else {
            return
        }

        guard let keyword = settings.keywords.first(where: { keyword in
            text.range(of: keyword, options: [.caseInsensitive, .diacriticInsensitive]) != nil
        }) else {
            return
        }

        let match = MatchedTelegramMessage(
            id: update.updateID,
            chatName: message.chat.displayName,
            senderName: message.senderName,
            text: text,
            keyword: keyword,
            receivedAt: Date(timeIntervalSince1970: TimeInterval(message.date))
        )

        lastMatch = match
        statusText = "Найдено: \(keyword)"
        appendLog("Найдено \"\(keyword)\" в \(message.chat.displayName): \(text.shortened(to: 120))")

        do {
            try await NotificationService.sendNotification(for: match)
        } catch {
            setError("Не удалось отправить уведомление: \(error.localizedDescription)")
        }
    }

    private func matchesChatFilter(_ chat: TelegramChat) -> Bool {
        let filter = settings.chatFilter.trimmed()
        guard !filter.isEmpty else {
            return true
        }

        if filter == "\(chat.id)" {
            return true
        }

        let normalizedFilter = filter
            .lowercased()
            .trimmingCharacters(in: CharacterSet(charactersIn: "@"))

        return chat.username?.lowercased() == normalizedFilter
    }

    private func appendLog(_ message: String) {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .medium
        let line = "[\(formatter.string(from: Date()))] \(message)"

        logEntries.insert(line, at: 0)
        if logEntries.count > 80 {
            logEntries.removeLast(logEntries.count - 80)
        }
    }

    private func setError(_ message: String) {
        statusText = "Ошибка: \(message)"
        appendLog("Ошибка: \(message)")
    }
}
