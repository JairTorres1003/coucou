#if !APPSTORE
import AppKit
import ApplicationServices

// Terminal apps Coucou can bring forward, and the ones whose Claude Code
// sessions it follows (Warp). Used by the jump-to-terminal actions.
enum TerminalApps {
    static let warpBundleIds = ["dev.warp.Warp-Stable", "dev.warp.Warp-Preview", "dev.warp.Warp"]

    static let bundleIds = ["com.apple.Terminal", "com.googlecode.iterm2",
                            "net.kovidgoyal.kitty", "com.mitchellh.ghostty"] + warpBundleIds

    /// Warp sets TERM_PROGRAM=WarpTerminal and its bundle id in the hook environment.
    static func isWarp(termProgram: String, bundleId: String) -> Bool {
        termProgram == "WarpTerminal" || warpBundleIds.contains(bundleId)
    }

    /// Brings forward the terminal the session runs in (`preferred`) if it is running,
    /// else the first running known terminal. With `project` (the session's folder name)
    /// it also raises the window whose title mentions it, when Accessibility allows.
    /// Returns false when no known terminal is running.
    @discardableResult
    static func activate(preferred: String?, project: String? = nil) -> Bool {
        let running = NSWorkspace.shared.runningApplications
        let candidates = ([preferred].compactMap { $0 } + bundleIds)
        for id in candidates {
            if let app = running.first(where: { $0.bundleIdentifier == id }) {
                if let project, !project.isEmpty { raiseWindow(of: app, titleContaining: project) }
                app.activate(options: .activateIgnoringOtherApps)
                return true
            }
        }
        return false
    }

    /// Launches the terminal the session runs in when it is not running. Returns false if unknown.
    @discardableResult
    static func launch(bundleId: String?) -> Bool {
        guard let bundleId,
              let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) else { return false }
        NSWorkspace.shared.openApplication(at: url, configuration: .init(), completionHandler: nil)
        return true
    }

    private static func raiseWindow(of app: NSRunningApplication, titleContaining needle: String) {
        guard AXIsProcessTrusted() else { return }
        let axApp = AXUIElementCreateApplication(app.processIdentifier)
        var ref: CFTypeRef?
        guard AXUIElementCopyAttributeValue(axApp, kAXWindowsAttribute as CFString, &ref) == .success,
              let windows = ref as? [AXUIElement] else { return }
        for window in windows {
            var titleRef: CFTypeRef?
            guard AXUIElementCopyAttributeValue(window, kAXTitleAttribute as CFString, &titleRef) == .success,
                  let title = titleRef as? String,
                  title.localizedCaseInsensitiveContains(needle) else { continue }
            AXUIElementPerformAction(window, kAXRaiseAction as CFString)
            return
        }
    }
}
#endif
