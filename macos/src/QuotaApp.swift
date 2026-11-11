import Cocoa

// Estruturas de dados
struct Bucket: Codable {
    let id: String?
    let name: String
    let remaining_pct: Int
    let reset_in: String?
    let detail: String?
}

struct Group: Codable {
    let name: String
    let description: String?
    let buckets: [Bucket]
}

struct QuotaData: Codable {
    let account: String
    let userName: String?
    let plan: String?
    let groups: [Group]
    let updated_at: String?
    var from_cache: Bool?
    var cache_age_seconds: Int?
    var timestamp: Double?
}

class QuotaManager {
    static let cachePath = "/tmp/antigravity_quota_cache.json"
    static let fetchScript = NSString(string: "~/.gemini/config/plugins/quota-monitor/scripts/fetch_quota.js").expandingTildeInPath
    
    static func loadQuota(force: Bool = false) -> QuotaData? {
        if !force {
            if let cached = readCache(), let ts = cached.timestamp, (Date().timeIntervalSince1970 - ts) < 60 {
                var c = cached
                c.from_cache = true
                c.cache_age_seconds = Int(Date().timeIntervalSince1970 - ts)
                return c
            }
        }
        return fetchLive()
    }
    
    static func readCache() -> QuotaData? {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: cachePath)) else { return nil }
        return try? JSONDecoder().decode(QuotaData.self, from: data)
    }
    
    static func fetchLive() -> QuotaData? {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        task.arguments = ["node", fetchScript]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = Pipe()
        
        do {
            try task.run()
            task.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let decoded = try? JSONDecoder().decode(QuotaData.self, from: data) {
                var saved = decoded
                saved.timestamp = Date().timeIntervalSince1970
                saved.from_cache = false
                saved.cache_age_seconds = 0
                if let encoded = try? JSONEncoder().encode(saved) {
                    try? encoded.write(to: URL(fileURLWithPath: cachePath))
                }
                return saved
            }
        } catch {
            print("Fetch error: \(error)")
        }
        return readCache()
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    var window: NSWindow!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupUI(force: CommandLine.arguments.contains("--force"))
    }
    
    func setupUI(force: Bool) {
        guard let quota = QuotaManager.loadQuota(force: force) else {
            NSApp.terminate(nil)
            return
        }
        
        let windowWidth: CGFloat = 460
        var contentHeight: CGFloat = 95
        for g in quota.groups {
            contentHeight += 36 + CGFloat(g.buckets.count * 52)
        }
        contentHeight += 60 // footer
        
        let windowRect = NSRect(x: 0, y: 0, width: windowWidth, height: min(contentHeight, 720))
        
        if window == nil {
            window = NSWindow(
                contentRect: windowRect,
                styleMask: [.titled, .closable, .fullSizeContentView],
                backing: .buffered,
                defer: false
            )
            window.titlebarAppearsTransparent = true
            window.title = "Antigravity Model Quota"
            window.isReleasedWhenClosed = false
            window.delegate = self
            window.level = .floating
            window.center()
        }
        
        // Visual Effect Background (Native Dark Vibrancy)
        let visualEffect = NSVisualEffectView(frame: window.contentView!.bounds)
        visualEffect.autoresizingMask = [.width, .height]
        visualEffect.material = .hudWindow
        visualEffect.blendingMode = .behindWindow
        visualEffect.state = .active
        window.contentView = visualEffect
        
        // Scroll view if content is tall
        let scrollView = NSScrollView(frame: NSRect(x: 0, y: 55, width: windowWidth, height: windowRect.height - 55))
        scrollView.hasVerticalScroller = contentHeight > 700
        scrollView.drawsBackground = false
        scrollView.autoresizingMask = [.width, .height]
        
        let contentView = NSView(frame: NSRect(x: 0, y: 0, width: windowWidth, height: contentHeight - 55))
        
        var currentY = contentView.frame.height - 18
        
        // Account & Plan
        let accountText = "👤 \(quota.account) • Plano \(quota.plan ?? "Pro")"
        let accountLabel = NSTextField(labelWithString: accountText)
        accountLabel.font = NSFont.systemFont(ofSize: 13, weight: .semibold)
        accountLabel.textColor = .white
        accountLabel.frame = NSRect(x: 24, y: currentY - 18, width: 400, height: 18)
        contentView.addSubview(accountLabel)
        currentY -= 22
        
        // Timestamp & cache info
        let cacheInfo = (quota.from_cache ?? false) ? " (Cache \(quota.cache_age_seconds ?? 0)s atrás)" : " (Tempo real)"
        let timeText = "Atualizado às \(quota.updated_at ?? "agora")\(cacheInfo)"
        let timeLabel = NSTextField(labelWithString: timeText)
        timeLabel.font = NSFont.systemFont(ofSize: 11, weight: .regular)
        timeLabel.textColor = NSColor(white: 0.6, alpha: 1.0)
        timeLabel.frame = NSRect(x: 24, y: currentY - 16, width: 400, height: 16)
        contentView.addSubview(timeLabel)
        currentY -= 24
        
        // Groups
        for g in quota.groups {
            let gHeader = NSTextField(labelWithString: g.name.uppercased())
            gHeader.font = NSFont.systemFont(ofSize: 10, weight: .bold)
            gHeader.textColor = NSColor(red: 0.65, green: 0.65, blue: 0.70, alpha: 1.0)
            gHeader.frame = NSRect(x: 24, y: currentY - 16, width: 400, height: 16)
            contentView.addSubview(gHeader)
            currentY -= 20
            
            let cardHeight = CGFloat(g.buckets.count * 48 + 12)
            let cardView = NSBox(frame: NSRect(x: 22, y: currentY - cardHeight, width: windowWidth - 44, height: cardHeight))
            cardView.boxType = .custom
            cardView.fillColor = NSColor(white: 0.15, alpha: 0.85)
            cardView.borderColor = NSColor(white: 0.28, alpha: 0.8)
            cardView.borderWidth = 1.0
            cardView.cornerRadius = 10
            contentView.addSubview(cardView)
            
            var cardY = cardHeight - 14
            for (idx, b) in g.buckets.enumerated() {
                if idx > 0 {
                    let sep = NSBox(frame: NSRect(x: 12, y: cardY - 2, width: cardView.frame.width - 24, height: 1))
                    sep.boxType = .custom
                    sep.fillColor = NSColor(white: 0.22, alpha: 0.7)
                    sep.borderColor = .clear
                    cardView.addSubview(sep)
                    cardY -= 8
                }
                
                let bName = NSTextField(labelWithString: b.name)
                bName.font = NSFont.systemFont(ofSize: 12, weight: .regular)
                bName.textColor = .white
                bName.frame = NSRect(x: 14, y: cardY - 18, width: 230, height: 18)
                cardView.addSubview(bName)
                
                let resetStr = (b.reset_in != nil && !b.reset_in!.isEmpty) ? " • \(b.reset_in!)" : ""
                let valText = "\(b.remaining_pct)%\(resetStr)"
                let bVal = NSTextField(labelWithString: valText)
                bVal.font = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .semibold)
                bVal.alignment = .right
                
                if b.remaining_pct > 50 {
                    bVal.textColor = NSColor(red: 0.20, green: 0.80, blue: 0.40, alpha: 1.0)
                } else if b.remaining_pct > 20 {
                    bVal.textColor = NSColor(red: 1.00, green: 0.65, blue: 0.15, alpha: 1.0)
                } else {
                    bVal.textColor = NSColor(red: 1.00, green: 0.30, blue: 0.30, alpha: 1.0)
                }
                bVal.frame = NSRect(x: cardView.frame.width - 180, y: cardY - 18, width: 166, height: 18)
                cardView.addSubview(bVal)
                cardY -= 22
                
                // Progress Bar Background
                let barBg = NSBox(frame: NSRect(x: 14, y: cardY - 6, width: cardView.frame.width - 28, height: 6))
                barBg.boxType = .custom
                barBg.fillColor = NSColor(white: 0.25, alpha: 1.0)
                barBg.borderColor = .clear
                barBg.cornerRadius = 3
                cardView.addSubview(barBg)
                
                // Progress Bar Fill
                let fillWidth = max(CGFloat(barBg.frame.width) * CGFloat(b.remaining_pct) / 100.0, 4)
                let barFill = NSBox(frame: NSRect(x: 14, y: cardY - 6, width: fillWidth, height: 6))
                barFill.boxType = .custom
                barFill.fillColor = bVal.textColor ?? NSColor.systemGreen
                barFill.borderColor = .clear
                barFill.cornerRadius = 3
                cardView.addSubview(barFill)
                
                cardY -= 14
            }
            
            currentY -= (cardHeight + 14)
        }
        
        scrollView.documentView = contentView
        visualEffect.addSubview(scrollView)
        
        // Footer Buttons
        let refreshBtn = NSButton(title: "🔄 Atualizar", target: self, action: #selector(refreshClicked))
        refreshBtn.bezelStyle = .rounded
        refreshBtn.frame = NSRect(x: 20, y: 14, width: 110, height: 28)
        refreshBtn.keyEquivalent = "r"
        refreshBtn.keyEquivalentModifierMask = .command
        visualEffect.addSubview(refreshBtn)
        
        let closeBtn = NSButton(title: "Fechar", target: self, action: #selector(closeClicked))
        closeBtn.bezelStyle = .rounded
        closeBtn.frame = NSRect(x: windowWidth - 110, y: 14, width: 90, height: 28)
        closeBtn.keyEquivalent = "\u{1b}" // Esc key
        visualEffect.addSubview(closeBtn)
        
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc func refreshClicked() {
        setupUI(force: true)
    }
    
    @objc func closeClicked() {
        NSApp.terminate(nil)
    }
    
    func windowWillClose(_ notification: Notification) {
        NSApp.terminate(nil)
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.run()
