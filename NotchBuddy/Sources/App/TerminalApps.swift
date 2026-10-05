#if !APPSTORE
import AppKit

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
    /// else the first running known terminal. Returns false when none is running.
    @discardableResult
    static func activate(preferred: String?) -> Bool {
        let running = NSWorkspace.shared.runningApplications
        let candidates = ([preferred].compactMap { $0 } + bundleIds)
        for id in candidates {
            if let app = running.first(where: { $0.bundleIdentifier == id }) {
                app.activate(options: .activateIgnoringOtherApps)
                return true
            }
        }
        return false
    }
}
#endif
