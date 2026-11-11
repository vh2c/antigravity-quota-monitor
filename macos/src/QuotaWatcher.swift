import Cocoa

class WatcherDelegate: NSObject, NSApplicationDelegate {
    let lastShownFile = NSString(string: "~/Library/Application Support/AntigravityQuota/last_shown.json").expandingTildeInPath
    let appUrl = URL(fileURLWithPath: "/Applications/Antigravity Quota.app")
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 1. Verifica se o Antigravity já está rodando neste momento (ex: inicialização do macOS com restauração de apps)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.checkAndLaunchIfRunning()
        }
        
        // 2. Inscreve-se nos eventos de abertura de aplicativos no macOS via NSWorkspace
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(appDidLaunch(_:)),
            name: NSWorkspace.didLaunchApplicationNotification,
            object: nil
        )
    }
    
    func shouldShow() -> Bool {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: lastShownFile)),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let ts = json["timestamp"] as? Double else {
            return true
        }
        // Cache de 60 segundos
        return (Date().timeIntervalSince1970 - ts) >= 60.0
    }
    
    func markShown() {
        let dir = (lastShownFile as NSString).deletingLastPathComponent
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        let json: [String: Any] = ["timestamp": Date().timeIntervalSince1970]
        if let data = try? JSONSerialization.data(withJSONObject: json) {
            try? data.write(to: URL(fileURLWithPath: lastShownFile))
        }
    }
    
    func isAntigravity(_ app: NSRunningApplication) -> Bool {
        if let id = app.bundleIdentifier?.lowercased() {
            if id == "com.google.antigravity" || id == "com.google.antigravity-ide" {
                return true
            }
        }
        if let name = app.localizedName?.lowercased() {
            if name == "antigravity" || name == "antigravity ide" {
                return true
            }
        }
        return false
    }
    
    func checkAndLaunchIfRunning() {
        for app in NSWorkspace.shared.runningApplications {
            if isAntigravity(app) {
                triggerPopup(reason: "already_running_at_startup")
                return
            }
        }
    }
    
    @objc func appDidLaunch(_ note: Notification) {
        guard let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else { return }
        if isAntigravity(app) {
            triggerPopup(reason: "app_launched_event")
        }
    }
    
    func triggerPopup(reason: String) {
        if shouldShow() {
            markShown()
            DispatchQueue.global().async {
                // Aguarda 2.5s para que o language_server do Antigravity inicialize e abra a porta local
                Thread.sleep(forTimeInterval: 2.5)
                let task = Process()
                task.executableURL = URL(fileURLWithPath: "/usr/bin/open")
                task.arguments = ["/Applications/Antigravity Quota.app"]
                try? task.run()
            }
        }
    }
}

let app = NSApplication.shared
let delegate = WatcherDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory) // Roda silenciosamente em background sem ícone no Dock
app.run()
