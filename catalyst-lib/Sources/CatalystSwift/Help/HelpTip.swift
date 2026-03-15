import Foundation

public struct HelpTip: Identifiable, Sendable {
    public let id: String
    public let category: String
    public let title: String
    public let description: String
    public let shortcut: String?
    public let icon: String

    public init(id: String, category: String, title: String, description: String, shortcut: String? = nil, icon: String) {
        self.id = id
        self.category = category
        self.title = title
        self.description = description
        self.shortcut = shortcut
        self.icon = icon
    }
}
