import Combine
import Foundation

final class AppSettings: ObservableObject {
    @Published var botToken: String {
        didSet { save() }
    }

    @Published var chatFilter: String {
        didSet { save() }
    }

    @Published var keywordsText: String {
        didSet { save() }
    }

    @Published var pollingInterval: Double {
        didSet { save() }
    }

    @Published var ignoreBacklogOnStart: Bool {
        didSet { save() }
    }

    @Published var lastUpdateID: Int64? {
        didSet { save() }
    }

    private let defaults: UserDefaults

    var keywords: [String] {
        keywordsText
            .components(separatedBy: CharacterSet(charactersIn: "\n,;"))
            .map { $0.trimmed() }
            .filter { !$0.isEmpty }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        botToken = defaults.string(forKey: Keys.botToken) ?? ""
        chatFilter = defaults.string(forKey: Keys.chatFilter) ?? ""
        keywordsText = defaults.string(forKey: Keys.keywordsText) ?? ""

        let savedInterval = defaults.double(forKey: Keys.pollingInterval)
        pollingInterval = savedInterval > 0 ? savedInterval : 5

        if defaults.object(forKey: Keys.ignoreBacklogOnStart) == nil {
            ignoreBacklogOnStart = true
        } else {
            ignoreBacklogOnStart = defaults.bool(forKey: Keys.ignoreBacklogOnStart)
        }

        if let savedUpdateID = defaults.object(forKey: Keys.lastUpdateID) as? NSNumber {
            lastUpdateID = savedUpdateID.int64Value
        } else {
            lastUpdateID = nil
        }
    }

    func resetOffset() {
        lastUpdateID = nil
    }

    private func save() {
        defaults.set(botToken, forKey: Keys.botToken)
        defaults.set(chatFilter, forKey: Keys.chatFilter)
        defaults.set(keywordsText, forKey: Keys.keywordsText)
        defaults.set(pollingInterval, forKey: Keys.pollingInterval)
        defaults.set(ignoreBacklogOnStart, forKey: Keys.ignoreBacklogOnStart)

        if let lastUpdateID {
            defaults.set(lastUpdateID, forKey: Keys.lastUpdateID)
        } else {
            defaults.removeObject(forKey: Keys.lastUpdateID)
        }
    }
}

private enum Keys {
    static let botToken = "botToken"
    static let chatFilter = "chatFilter"
    static let keywordsText = "keywordsText"
    static let pollingInterval = "pollingInterval"
    static let ignoreBacklogOnStart = "ignoreBacklogOnStart"
    static let lastUpdateID = "lastUpdateID"
}
