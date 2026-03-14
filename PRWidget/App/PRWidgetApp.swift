import SwiftUI

@main
struct PRWidgetApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // LSUIElement app — no windows managed by SwiftUI.
        // The floating panel and settings window are managed by AppDelegate.
        WindowGroup(id: "never-shown") {
            EmptyView()
        }
        .defaultSize(width: 0, height: 0)
    }
}
