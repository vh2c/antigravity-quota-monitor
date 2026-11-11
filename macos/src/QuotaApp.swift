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
    static let appSupportDir: String = {
        let path = NSString(string: "~/Library/Application Support/AntigravityQuota").expandingTildeInPath
        try? FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true)
        return path
    }()
    
    static var cachePath: String {
        return (appSupportDir as NSString).appendingPathComponent("quota_cache.json")
    }
    
    static var lastShownPath: String {
        return (appSupportDir as NSString).appendingPathComponent("last_shown.json")
    }
    
    static let fetchScript = NSString(string: "~/.gemini/config/plugins/quota-monitor/scripts/fetch_quota.js").expandingTildeInPath
    
    static func markShown() {
        let json: [String: Any] = ["timestamp": Date().timeIntervalSince1970]
        if let data = try? JSONSerialization.data(withJSONObject: json) {
            try? data.write(to: URL(fileURLWithPath: lastShownPath))
        }
    }
    
    static func findNodeBinary() -> String {
        let fileManager = FileManager.default
        let wellKnownPaths = [
            "/opt/homebrew/bin/node",
            "/usr/local/bin/node",
            "/usr/bin/node",
            "/bin/node"
        ]
        for path in wellKnownPaths {
            if fileManager.isExecutableFile(atPath: path) {
                return path
            }
        }
        
        let nvmBase = NSString(string: "~/.nvm/versions/node").expandingTildeInPath
        if let versions = try? fileManager.contentsOfDirectory(atPath: nvmBase) {
            for v in versions.sorted().reversed() {
                let candidate = (nvmBase as NSString).appendingPathComponent("\(v)/bin/node")
                if fileManager.isExecutableFile(atPath: candidate) {
                    return candidate
                }
            }
        }
        
        return "node"
    }
    
    static func loadQuota(force: Bool = false, maxRetries: Int = 3) -> QuotaData? {
        if !force {
            if let cached = readCache(), let ts = cached.timestamp, (Date().timeIntervalSince1970 - ts) < 30 {
                var c = cached
                c.from_cache = true
                c.cache_age_seconds = Int(Date().timeIntervalSince1970 - ts)
                return c
            }
        }
        
        for attempt in 1...maxRetries {
            if let live = fetchLive() {
                markShown()
                return live
            }
            if attempt < maxRetries {
                Thread.sleep(forTimeInterval: 0.5)
            }
        }
        
        if let cached = readCache() {
            markShown()
            return cached
        }
        return nil
    }
    
    static func readCache() -> QuotaData? {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: cachePath)) else { return nil }
        return try? JSONDecoder().decode(QuotaData.self, from: data)
    }
    
    static func fetchLive() -> QuotaData? {
        let nodeBin = findNodeBinary()
        let task = Process()
        if nodeBin.hasPrefix("/") {
            task.executableURL = URL(fileURLWithPath: nodeBin)
            task.arguments = [fetchScript]
        } else {
            task.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            task.arguments = ["node", fetchScript]
        }
        
        var env = ProcessInfo.processInfo.environment
        var searchPaths: [String] = [
            "/opt/homebrew/bin",
            "/opt/homebrew/sbin",
            "/usr/local/bin",
            "/usr/bin",
            "/bin",
            "/usr/sbin",
            "/sbin"
        ]
        let nvmBase = NSString(string: "~/.nvm/versions/node").expandingTildeInPath
        if let versions = try? FileManager.default.contentsOfDirectory(atPath: nvmBase) {
            for v in versions.sorted().reversed() {
                searchPaths.append((nvmBase as NSString).appendingPathComponent("\(v)/bin"))
            }
        }
        if let currentPath = env["PATH"] {
            searchPaths.append(currentPath)
        }
        env["PATH"] = searchPaths.joined(separator: ":")
        env["HOME"] = NSHomeDirectory()
        env["USER"] = NSUserName()
        task.environment = env
        
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
        return nil
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    var window: NSWindow!
    var autoRefreshTimer: Timer?
    var refreshBtn: NSButton?
    var isRefreshing: Bool = false
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        let force = CommandLine.arguments.contains("--force")
        if let initialQuota = QuotaManager.loadQuota(force: force, maxRetries: 3) {
            setupUI(with: initialQuota)
            startAutoRefreshTimer()
        } else {
            NSApp.terminate(nil)
        }
    }
    
    func startAutoRefreshTimer() {
        autoRefreshTimer?.invalidate()
        autoRefreshTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.performRefresh(animated: false)
        }
    }
    
    @objc func refreshClicked() {
        performRefresh(animated: true)
    }
    
    func performRefresh(animated: Bool) {
        if isRefreshing { return }
        isRefreshing = true
        
        if animated {
            refreshBtn?.isEnabled = false
            refreshBtn?.attributedTitle = NSAttributedString(
                string: "Atualizando...",
                attributes: [
                    .foregroundColor: NSColor(white: 0.50, alpha: 1.0),
                    .font: NSFont.systemFont(ofSize: 12, weight: .semibold)
                ]
            )
        }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let quota = QuotaManager.loadQuota(force: true, maxRetries: 2)
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isRefreshing = false
                if let quota = quota {
                    self.setupUI(with: quota)
                } else {
                    self.resetRefreshBtn()
                }
            }
        }
    }
    
    func resetRefreshBtn() {
        let btnText = NSColor(srgbRed: 0x18/255.0, green: 0x18/255.0, blue: 0x18/255.0, alpha: 1.0)
        refreshBtn?.isEnabled = true
        refreshBtn?.attributedTitle = NSAttributedString(
            string: "Atualizar",
            attributes: [
                .foregroundColor: btnText,
                .font: NSFont.systemFont(ofSize: 12, weight: .semibold)
            ]
        )
        if let symbol = NSImage(systemSymbolName: "arrow.clockwise", accessibilityDescription: "Atualizar") {
            let config = NSImage.SymbolConfiguration(pointSize: 10, weight: .bold)
            if #available(macOS 12.0, *) {
                let tinted = config.applying(.init(paletteColors: [btnText]))
                refreshBtn?.image = symbol.withSymbolConfiguration(tinted)
            } else {
                refreshBtn?.image = symbol.withSymbolConfiguration(config)
                refreshBtn?.contentTintColor = btnText
            }
        }
    }
    
    func setupUI(with quota: QuotaData) {
        
        // Cores oficiais do Antigravity: Fundo #181818, Campos #1F1F1F, 100% opaco
        let colorBg18 = NSColor(srgbRed: 0x18/255.0, green: 0x18/255.0, blue: 0x18/255.0, alpha: 1.0)
        let colorField1F = NSColor(srgbRed: 0x1F/255.0, green: 0x1F/255.0, blue: 0x1F/255.0, alpha: 1.0)
        let colorBorder = NSColor(srgbRed: 0x2C/255.0, green: 0x2C/255.0, blue: 0x2C/255.0, alpha: 1.0)
        let colorSep = NSColor(srgbRed: 0x28/255.0, green: 0x28/255.0, blue: 0x28/255.0, alpha: 1.0)
        let colorTrack = NSColor(srgbRed: 0x2D/255.0, green: 0x2D/255.0, blue: 0x2D/255.0, alpha: 1.0)
        
        let windowWidth: CGFloat = 460
        var totalCardsHeight: CGFloat = 0
        for g in quota.groups {
            totalCardsHeight += 32 + CGFloat(g.buckets.count * 48 + 14)
        }
        let contentHeight: CGFloat = 65 + totalCardsHeight + 10
        let windowHeight = min(contentHeight + 52, 700)
        
        let windowRect = NSRect(x: 0, y: 0, width: windowWidth, height: windowHeight)
        
        if window == nil {
            window = NSWindow(
                contentRect: windowRect,
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            window.title = "Antigravity Model Quota"
            window.isReleasedWhenClosed = false
            window.delegate = self
            window.level = .normal // Permite ir para segundo plano normalmente
            window.center()
        }
        
        // Fundo 100% sólido sem transparência
        window.backgroundColor = colorBg18
        window.isOpaque = true
        
        let mainView = NSView(frame: window.contentView!.bounds)
        mainView.wantsLayer = true
        mainView.layer?.backgroundColor = colorBg18.cgColor
        mainView.autoresizingMask = [.width, .height]
        window.contentView = mainView
        
        // Área com scroll para o conteúdo
        let scrollViewHeight = windowHeight - 50
        let scrollView = NSScrollView(frame: NSRect(x: 0, y: 50, width: windowWidth, height: scrollViewHeight))
        scrollView.hasVerticalScroller = contentHeight > scrollViewHeight
        scrollView.drawsBackground = true
        scrollView.backgroundColor = colorBg18
        scrollView.autoresizingMask = [.width, .height]
        
        let actualContentHeight = max(contentHeight, scrollViewHeight)
        let contentView = NSView(frame: NSRect(x: 0, y: 0, width: windowWidth, height: actualContentHeight))
        contentView.wantsLayer = true
        contentView.layer?.backgroundColor = colorBg18.cgColor
        
        var currentY = actualContentHeight - 16
        
        // Linha 1: Conta & Plano (sem emojis, tipografia monocromática limpa)
        let accountText = "\(quota.account) • Plano \(quota.plan ?? "Pro")"
        let accountLabel = NSTextField(labelWithString: accountText)
        accountLabel.font = NSFont.systemFont(ofSize: 13, weight: .semibold)
        accountLabel.textColor = .white
        accountLabel.frame = NSRect(x: 22, y: currentY - 18, width: 416, height: 18)
        contentView.addSubview(accountLabel)
        currentY -= 22
        
        // Linha 2: Timestamp & Status do Cache (monocromático)
        let cacheInfo = (quota.from_cache ?? false) ? " (Cache \(quota.cache_age_seconds ?? 0)s atrás)" : " (Tempo real)"
        let timeText = "Atualizado às \(quota.updated_at ?? "agora")\(cacheInfo)"
        let timeLabel = NSTextField(labelWithString: timeText)
        timeLabel.font = NSFont.systemFont(ofSize: 11, weight: .regular)
        timeLabel.textColor = NSColor(white: 0.65, alpha: 1.0)
        timeLabel.frame = NSRect(x: 22, y: currentY - 15, width: 416, height: 15)
        contentView.addSubview(timeLabel)
        currentY -= 24
        
        // Grupos de Modelos com cartões no fundo #1F1F1F sólido
        for g in quota.groups {
            let gHeader = NSTextField(labelWithString: g.name.uppercased())
            gHeader.font = NSFont.systemFont(ofSize: 10, weight: .bold)
            gHeader.textColor = NSColor(white: 0.60, alpha: 1.0)
            gHeader.frame = NSRect(x: 22, y: currentY - 14, width: 416, height: 14)
            contentView.addSubview(gHeader)
            currentY -= 18
            
            let cardHeight = CGFloat(g.buckets.count * 46 + 12)
            let cardView = NSBox(frame: NSRect(x: 20, y: currentY - cardHeight, width: windowWidth - 40, height: cardHeight))
            cardView.boxType = .custom
            cardView.fillColor = colorField1F
            cardView.borderColor = colorBorder
            cardView.borderWidth = 1.0
            cardView.cornerRadius = 8
            contentView.addSubview(cardView)
            
            var cardY = cardHeight - 12
            for (idx, b) in g.buckets.enumerated() {
                if idx > 0 {
                    let sep = NSBox(frame: NSRect(x: 12, y: cardY - 2, width: cardView.frame.width - 24, height: 1))
                    sep.boxType = .custom
                    sep.fillColor = colorSep
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
                cardY -= 20
                
                // Barra de progresso com track sólido #2D2D2D
                let barBg = NSBox(frame: NSRect(x: 14, y: cardY - 6, width: cardView.frame.width - 28, height: 6))
                barBg.boxType = .custom
                barBg.fillColor = colorTrack
                barBg.borderColor = .clear
                barBg.cornerRadius = 3
                cardView.addSubview(barBg)
                
                let fillWidth = max(CGFloat(barBg.frame.width) * CGFloat(b.remaining_pct) / 100.0, 4)
                let barFill = NSBox(frame: NSRect(x: 14, y: cardY - 6, width: fillWidth, height: 6))
                barFill.boxType = .custom
                barFill.fillColor = bVal.textColor ?? NSColor.systemGreen
                barFill.borderColor = .clear
                barFill.cornerRadius = 3
                cardView.addSubview(barFill)
                
                cardY -= 14
            }
            
            currentY -= (cardHeight + 12)
        }
        
        scrollView.documentView = contentView
        mainView.addSubview(scrollView)
        
        // Rodapé com botões claros, de alta visibilidade e 100% monocromáticos
        let btnBg = NSColor(srgbRed: 0xEE/255.0, green: 0xEE/255.0, blue: 0xF0/255.0, alpha: 1.0)
        let btnText = NSColor(srgbRed: 0x18/255.0, green: 0x18/255.0, blue: 0x18/255.0, alpha: 1.0)
        
        // Botão Atualizar
        let refreshBtn = NSButton(title: "", target: self, action: #selector(refreshClicked))
        refreshBtn.isBordered = false
        refreshBtn.wantsLayer = true
        refreshBtn.layer?.backgroundColor = btnBg.cgColor
        refreshBtn.layer?.cornerRadius = 6
        refreshBtn.frame = NSRect(x: 20, y: 12, width: 104, height: 30)
        refreshBtn.keyEquivalent = "r"
        refreshBtn.keyEquivalentModifierMask = .command
        refreshBtn.imagePosition = .imageLeading
        refreshBtn.imageHugsTitle = true
        refreshBtn.attributedTitle = NSAttributedString(
            string: "Atualizar",
            attributes: [
                .foregroundColor: btnText,
                .font: NSFont.systemFont(ofSize: 12, weight: .semibold)
            ]
        )
        if let symbol = NSImage(systemSymbolName: "arrow.clockwise", accessibilityDescription: "Atualizar") {
            let config = NSImage.SymbolConfiguration(pointSize: 10, weight: .bold)
            if #available(macOS 12.0, *) {
                let tinted = config.applying(.init(paletteColors: [btnText]))
                refreshBtn.image = symbol.withSymbolConfiguration(tinted)
            } else {
                refreshBtn.image = symbol.withSymbolConfiguration(config)
                refreshBtn.contentTintColor = btnText
            }
        }
        self.refreshBtn = refreshBtn
        mainView.addSubview(refreshBtn)
        
        // Botão Fechar
        let closeBtn = NSButton(title: "", target: self, action: #selector(closeClicked))
        closeBtn.isBordered = false
        closeBtn.wantsLayer = true
        closeBtn.layer?.backgroundColor = btnBg.cgColor
        closeBtn.layer?.cornerRadius = 6
        closeBtn.frame = NSRect(x: windowWidth - 110, y: 12, width: 90, height: 30)
        closeBtn.keyEquivalent = "\u{1b}" // Esc
        closeBtn.attributedTitle = NSAttributedString(
            string: "Fechar",
            attributes: [
                .foregroundColor: btnText,
                .font: NSFont.systemFont(ofSize: 12, weight: .semibold)
            ]
        )
        mainView.addSubview(closeBtn)
        
        // Marca vh2c.com.br centralizada no rodapé
        let brandBtn = NSButton(title: "", target: self, action: #selector(brandClicked))
        brandBtn.isBordered = false
        brandBtn.frame = NSRect(x: 130, y: 17, width: windowWidth - 250, height: 20)
        let brandAttr = NSAttributedString(
            string: "vh2c.com.br",
            attributes: [
                .foregroundColor: NSColor(white: 0.40, alpha: 1.0),
                .font: NSFont.systemFont(ofSize: 10, weight: .regular)
            ]
        )
        brandBtn.attributedTitle = brandAttr
        mainView.addSubview(brandBtn)
        
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc func brandClicked() {
        if let url = URL(string: "https://vh2c.com.br") {
            NSWorkspace.shared.open(url)
        }
    }
    
    @objc func closeClicked() {
        autoRefreshTimer?.invalidate()
        autoRefreshTimer = nil
        NSApp.terminate(nil)
    }
    
    func windowWillClose(_ notification: Notification) {
        autoRefreshTimer?.invalidate()
        autoRefreshTimer = nil
        NSApp.terminate(nil)
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory) // Executa como utilitário sem ícone 'exec' no Dock
app.run()
