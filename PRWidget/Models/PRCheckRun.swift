import Foundation

struct PRCheckRun: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let status: String
    let conclusion: String?
    let url: URL?

    var ciStatus: CIStatus {
        if let conclusion {
            switch conclusion.uppercased() {
            case "SUCCESS": return .success
            case "FAILURE": return .failure
            case "NEUTRAL", "SKIPPED": return .success
            default: return .error
            }
        }
        switch status.uppercased() {
        case "COMPLETED": return .unknown
        case "IN_PROGRESS", "QUEUED", "REQUESTED", "WAITING", "PENDING": return .pending
        default: return .unknown
        }
    }
}
