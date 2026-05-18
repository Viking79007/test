import SwiftUI

struct ContentView: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject var monitor: TelegramMonitor

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            header
            configuration
            controls
            recentMatch
            logs
        }
        .padding(24)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Telegram Keyword Notifier")
                .font(.largeTitle.bold())
            Text("Следит за сообщениями Telegram-бота и показывает уведомления macOS при совпадении ключевых слов.")
                .foregroundStyle(.secondary)
        }
    }

    private var configuration: some View {
        GroupBox("Настройки") {
            VStack(alignment: .leading, spacing: 14) {
                SecureField("Токен бота от @BotFather", text: $settings.botToken)
                    .textFieldStyle(.roundedBorder)

                TextField("ID чата или @username канала/группы (можно оставить пустым)", text: $settings.chatFilter)
                    .textFieldStyle(.roundedBorder)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Ключевые слова")
                    TextEditor(text: $settings.keywordsText)
                        .font(.body.monospaced())
                        .frame(minHeight: 90)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.secondary.opacity(0.25))
                        )
                    Text("Разделяйте слова и фразы переносом строки, запятой или точкой с запятой.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("Интервал проверки")
                    Slider(value: $settings.pollingInterval, in: 1...120, step: 1)
                    Text("\(Int(settings.pollingInterval)) сек.")
                        .monospacedDigit()
                        .frame(width: 58, alignment: .trailing)
                }

                Toggle("Пропускать старые сообщения при запуске", isOn: $settings.ignoreBacklogOnStart)
            }
            .padding(.vertical, 8)
        }
    }

    private var controls: some View {
        HStack(spacing: 12) {
            Button {
                if monitor.isRunning {
                    monitor.stop()
                } else {
                    monitor.start()
                }
            } label: {
                Text(monitor.isRunning ? "Остановить" : "Запустить")
                    .frame(width: 110)
            }
            .keyboardShortcut(.defaultAction)

            Button("Разрешить уведомления") {
                monitor.requestNotificationPermission()
            }

            Button("Сбросить позицию") {
                settings.resetOffset()
            }
            .disabled(monitor.isRunning)

            Spacer()

            Text(monitor.statusText)
                .foregroundColor(monitor.statusText.hasPrefix("Ошибка") ? .red : .secondary)
                .lineLimit(1)
        }
    }

    @ViewBuilder
    private var recentMatch: some View {
        if let match = monitor.lastMatch {
            GroupBox("Последнее совпадение") {
                VStack(alignment: .leading, spacing: 4) {
                    Text(match.keyword)
                        .font(.headline)
                    Text("\(match.chatName) - \(match.senderName)")
                        .foregroundStyle(.secondary)
                    Text(match.text)
                        .lineLimit(3)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 4)
            }
        }
    }

    private var logs: some View {
        GroupBox("Журнал") {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 6) {
                    ForEach(monitor.logEntries, id: \.self) { entry in
                        Text(entry)
                            .font(.caption.monospaced())
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.vertical, 4)
            }
            .frame(minHeight: 130)
        }
    }
}
