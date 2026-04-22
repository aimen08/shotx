import Foundation

enum DesktopIcons {
    static func isVisible() -> Bool {
        let task = Process()
        task.launchPath = "/usr/bin/defaults"
        task.arguments = ["read", "com.apple.finder", "CreateDesktop"]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = Pipe()
        do {
            try task.run()
            task.waitUntilExit()
        } catch {
            return true
        }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let str = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        // Default (unset) is visible; treat missing/true/1 as visible.
        if str.isEmpty { return true }
        return str == "1" || str.lowercased() == "true"
    }

    static func setVisible(_ visible: Bool) {
        let writer = Process()
        writer.launchPath = "/usr/bin/defaults"
        writer.arguments = [
            "write", "com.apple.finder", "CreateDesktop",
            "-bool", visible ? "true" : "false"
        ]
        try? writer.run()
        writer.waitUntilExit()

        let kill = Process()
        kill.launchPath = "/usr/bin/killall"
        kill.arguments = ["Finder"]
        try? kill.run()
    }

    static func toggle() {
        setVisible(!isVisible())
    }
}
