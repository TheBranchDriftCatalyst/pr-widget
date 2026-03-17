import SwiftUI

private struct OpenDiffPanelKey: @preconcurrency EnvironmentKey {
    @MainActor static let defaultValue: @Sendable (PullRequest) -> Void = { _ in }
}

extension EnvironmentValues {
    var openDiffPanel: @Sendable (PullRequest) -> Void {
        get { self[OpenDiffPanelKey.self] }
        set { self[OpenDiffPanelKey.self] = newValue }
    }
}
