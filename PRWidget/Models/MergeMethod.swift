import Foundation

enum MergeMethod: String, CaseIterable, Sendable {
    case squash = "SQUASH"
    case merge = "MERGE"
    case rebase = "REBASE"

    var displayName: String {
        switch self {
        case .squash: "Squash and merge"
        case .merge: "Create a merge commit"
        case .rebase: "Rebase and merge"
        }
    }
}
