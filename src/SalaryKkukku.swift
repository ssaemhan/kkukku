import AppKit
import SwiftUI

final class SalaryModel: ObservableObject {
    @Published var now = Date()
    @Published var monthly: Double = UserDefaults.standard.object(forKey: "monthlySalary") as? Double ?? 3_000_000
    @Published var weekdays: Set<Int> = Set((UserDefaults.standard.array(forKey: "workWeekdays") as? [Int]) ?? Array(1...7))
    @Published var startMinute: Int = UserDefaults.standard.object(forKey: "workStartMinute") as? Int ?? 0
    @Published var endMinute: Int = UserDefaults.standard.object(forKey: "workEndMinute") as? Int ?? 1440
    private var timer: Timer?
    init() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in self?.now = Date() }
    }
    var earned: Int {
        earnedSalary(monthly: monthly, now: now, weekdays: weekdays, startMinute: startMinute, endMinute: endMinute)
    }

    var monthlyLabel: String { Int(monthly).formatted(.number.locale(Locale(identifier: "ko_KR"))) }
}

struct BlinkingPigeon: View {
    let icon: NSImage
    @State private var eyesClosed = false
    @State private var headAngle = 0.0

    private var artwork: some View {
        Image(nsImage: icon)
            .resizable().interpolation(.none).scaledToFit()
            .frame(width: 130, height: 130)
            .overlay(alignment: .topLeading) {
                if eyesClosed {
                    // Cover only the pupil, preserving the original pale eye ring.
                    Canvas { context, size in
                        let scale = size.width / 512
                        let lid = CGRect(x: 184 * scale, y: 99 * scale,
                                         width: 30 * scale, height: 29 * scale)
                        context.fill(Path(ellipseIn: lid),
                                     with: .color(Color(red: 0.89, green: 0.85, blue: 0.72)))
                        let crease = CGRect(x: 187 * scale, y: 113 * scale,
                                            width: 24 * scale, height: 4 * scale)
                        context.fill(Path(crease),
                                     with: .color(Color(red: 0.10, green: 0.15, blue: 0.20)))
                    }
                    .allowsHitTesting(false)
                }
            }
    }

    var body: some View {
        ZStack {
            // One shared neck boundary: rotated pixels cannot protrude into the body.
            artwork.mask(alignment: .bottom) {
                Rectangle().frame(height: 130 * (512 - 180) / 512)
            }
            artwork
                .rotationEffect(.degrees(headAngle), anchor: UnitPoint(x: 253.0 / 512, y: 180.0 / 512))
                .mask(alignment: .top) {
                    Rectangle().frame(height: 130 * 180 / 512)
                }
        }
        .frame(width: 130, height: 130)
        .accessibilityLabel("꾸꾸")
        .task {
            do {
                try await Task.sleep(nanoseconds: 6_000_000_000)
                while !Task.isCancelled {
                    withAnimation(.easeInOut(duration: 0.35)) { headAngle = -14 }
                    try await Task.sleep(nanoseconds: 700_000_000)
                    withAnimation(.easeInOut(duration: 0.18)) { headAngle = -18 }
                    try await Task.sleep(nanoseconds: 250_000_000)
                    withAnimation(.easeInOut(duration: 0.18)) { headAngle = -13 }
                    try await Task.sleep(nanoseconds: 350_000_000)
                    withAnimation(.easeInOut(duration: 0.4)) { headAngle = 0 }
                    // 1.3 seconds of action + 4.7 seconds = six seconds between starts.
                    try await Task.sleep(nanoseconds: 4_700_000_000)
                }
            } catch {
                headAngle = 0
            }
        }
        .task {
            do {
                try await Task.sleep(nanoseconds: 2_000_000_000)
                while !Task.isCancelled {
                    eyesClosed = true
                    try await Task.sleep(nanoseconds: 150_000_000)
                    eyesClosed = false
                    try await Task.sleep(nanoseconds: 1_850_000_000)
                }
            } catch {
                eyesClosed = false
            }
        }
    }
}

struct SalaryView: View {
    @ObservedObject var model: SalaryModel
    var body: some View {
        VStack(alignment: .center, spacing: -6) {
            VStack(alignment: .center, spacing: 0) {
                Text("지금까지 번 돈")
                    .font(.system(size: 12, weight: .medium)).foregroundStyle(.secondary)
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(model.earned, format: .number.locale(Locale(identifier: "ko_KR")))
                        .font(.system(size: 12, weight: .bold, design: .rounded)).monospacedDigit()
                        .tracking(-0.3)
                        .contentTransition(.numericText(value: Double(model.earned)))
                        .animation(.easeOut(duration: 0.25), value: model.earned)
                    Text("원").font(.system(size: 12, weight: .medium))
                }
            }
            .fixedSize(horizontal: true, vertical: false)
            .padding(.horizontal, 19)
            .padding(.vertical, 8)
            .background(.regularMaterial, in: Capsule())
            .overlay(Capsule().stroke(.white.opacity(0.15), lineWidth: 1))
            .padding(.trailing, 16)
            if let url = Bundle.main.url(forResource: "pigeon", withExtension: "png"),
               let icon = NSImage(contentsOf: url) {
                BlinkingPigeon(icon: icon)
            }
        }
        .padding(6)
        .fixedSize()
        .help("드래그해 위치를 옮기세요. 우클릭 또는 Control+클릭으로 설정과 종료 메뉴를 열 수 있습니다.")
    }
}

final class OverlayPanel: NSPanel {
    var settingsMenu: NSMenu?
    override func sendEvent(_ event: NSEvent) {
        let isContextClick = event.type == .rightMouseDown ||
            (event.type == .leftMouseDown && event.modifierFlags.contains(.control))
        if isContextClick, let menu = settingsMenu, let view = contentView {
            NSMenu.popUpContextMenu(menu, with: event, for: view)
            return
        }
        // SwiftUI content inside NSHostingView swallows mouse-down, so
        // isMovableByWindowBackground alone never moves this borderless panel.
        // Start a native window drag directly on left mouse-down instead.
        if event.type == .leftMouseDown {
            performDrag(with: event)
            return
        }
        super.sendEvent(event)
    }
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

final class SalarySettingsDialog: NSObject, NSWindowDelegate {
    let window = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 398, height: 420),
                         styleMask: [.titled, .closable], backing: .buffered, defer: false)
    var messageText = ""
    var informativeText = ""
    var accessoryView: NSView?
    private var buttons: [NSButton] = []
    private var prepared = false

    override init() {
        super.init()
        window.title = "급여 설정"
        window.isReleasedWhenClosed = false
        window.delegate = self
    }
    func addButton(withTitle title: String) {
        let button = NSButton(title: title, target: self, action: #selector(choose(_:)))
        button.tag = buttons.count
        button.bezelStyle = .rounded
        button.keyEquivalent = buttons.isEmpty ? "\r" : "\u{1b}"
        buttons.append(button)
    }
    @objc private func choose(_ sender: NSButton) {
        NSApp.stopModal(withCode: sender.tag == 0 ? .alertFirstButtonReturn : .alertSecondButtonReturn)
        window.orderOut(nil)
    }
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        NSApp.stopModal(withCode: .alertSecondButtonReturn)
        window.orderOut(nil)
        return false
    }
    func runModal() -> NSApplication.ModalResponse {
        if !prepared, let content = window.contentView, let accessory = accessoryView {
            let title = NSTextField(wrappingLabelWithString: messageText)
            title.font = .boldSystemFont(ofSize: 17)
            let explanation = NSTextField(wrappingLabelWithString: informativeText)
            explanation.font = .systemFont(ofSize: 12)
            explanation.textColor = .secondaryLabelColor
            let buttonRow = NSStackView(views: Array(buttons.reversed()))
            buttonRow.orientation = .horizontal
            buttonRow.spacing = 8
            let stack = NSStackView(views: [title, explanation, accessory, buttonRow])
            stack.orientation = .vertical
            stack.alignment = .leading
            stack.spacing = 14
            stack.translatesAutoresizingMaskIntoConstraints = false
            content.addSubview(stack)
            NSLayoutConstraint.activate([
                stack.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 24),
                stack.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -24),
                stack.topAnchor.constraint(equalTo: content.topAnchor, constant: 22),
                title.widthAnchor.constraint(equalToConstant: 350),
                explanation.widthAnchor.constraint(equalToConstant: 350),
                accessory.widthAnchor.constraint(equalToConstant: 350),
                accessory.heightAnchor.constraint(equalToConstant: 240)
            ])
            content.layoutSubtreeIfNeeded()
            window.setContentSize(NSSize(width: 398, height: stack.fittingSize.height + 44))
            window.center()
            prepared = true
        }
        window.makeKeyAndOrderFront(nil)
        return NSApp.runModal(for: window)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate, NSTextFieldDelegate {
    var settingsOpen = false
    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls where url.scheme == "salary-kkukku" {
            guard url.query == nil, url.fragment == nil, url.path.isEmpty || url.path == "/" else { continue }
            switch url.host {
            case "settings": changeSalary()
            case "show": panel?.orderFrontRegardless()
            case "hide": panel?.orderOut(nil)
            case "quit": NSApp.terminate(nil)
            default: break
            }
        }
    }
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        panel?.orderFrontRegardless()
        return true
    }
    weak var salaryInput: NSTextField?

    func controlTextDidChange(_ notification: Notification) {
        guard let field = notification.object as? NSTextField, field === salaryInput else { return }
        let text = field.stringValue
        let digits = text.replacingOccurrences(of: ",", with: "")
        guard !digits.isEmpty, digits.allSatisfy({ $0 >= "0" && $0 <= "9" }), let amount = Int(digits) else { return }
        let formatted = amount.formatted(.number.locale(Locale(identifier: "en_US")))
        guard formatted != text else { return }
        let editor = field.currentEditor()
        let selection = editor?.selectedRange ?? NSRange(location: (text as NSString).length, length: 0)
        func digitCount(_ offset: Int) -> Int {
            let prefix = (text as NSString).substring(to: min(offset, (text as NSString).length))
            return prefix.filter { $0 >= "0" && $0 <= "9" }.count
        }
        func caretPosition(_ count: Int) -> Int {
            if count == 0 { return 0 }
            var seen = 0
            for (index, character) in formatted.enumerated() {
                if character >= "0" && character <= "9" { seen += 1 }
                if seen >= count { return index + 1 }
            }
            return formatted.utf16.count
        }
        let start = caretPosition(digitCount(selection.location))
        let end = caretPosition(digitCount(NSMaxRange(selection)))
        field.stringValue = formatted
        editor?.selectedRange = NSRange(location: start, length: max(0, end - start))
    }

    let model = SalaryModel()
    var panel: OverlayPanel!
    var status: NSStatusItem!
    var layoutTimer: Timer?
    func resizeWidgetToFit() {
        guard let panel = panel, let view = panel.contentView else { return }
        let size = view.fittingSize
        guard size.width > 0, size.height > 0,
              abs(panel.frame.width - size.width) > 0.5 || abs(panel.frame.height - size.height) > 0.5 else { return }
        let old = panel.frame
        panel.setFrame(NSRect(x: old.midX - size.width / 2, y: old.maxY - size.height,
                              width: size.width, height: size.height), display: true)
    }
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        panel = OverlayPanel(contentRect: NSRect(x: 0, y: 0, width: 210, height: 48), styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isMovableByWindowBackground = true
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.contentView = NSHostingView(rootView: SalaryView(model: model))
        if let screen = NSScreen.main {
            panel.setFrameOrigin(NSPoint(x: screen.visibleFrame.maxX - 330, y: screen.visibleFrame.minY + 190))
        }
        panel.setFrameAutosaveName("SalaryKkukkuPosition")
        if let view = panel.contentView { panel.setContentSize(view.fittingSize) }
        if !NSScreen.screens.contains(where: { $0.visibleFrame.intersects(panel.frame) }), let screen = NSScreen.main {
            panel.setFrameOrigin(NSPoint(x: screen.visibleFrame.maxX - 330, y: screen.visibleFrame.minY + 190))
        }
        panel.orderFrontRegardless()
        status = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        status.button?.title = "₩"
        status.button?.toolTip = "Salary Kkukku"
        let menu = NSMenu()
        let title = NSMenuItem(title: "Salary Kkukku", action: nil, keyEquivalent: "")
        menu.addItem(title)
        menu.addItem(.separator())
        add(menu, "월급·근무 요일·시간 설정…", #selector(changeSalary))
        add(menu, "Kkukku 보이기 / 숨기기", #selector(toggle))
        add(menu, "계산 기준 보기", #selector(showInfo))
        menu.addItem(.separator())
        add(menu, "종료", #selector(quit))
        status.menu = menu
        panel.settingsMenu = menu
        layoutTimer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in self?.resizeWidgetToFit() }
        RunLoop.main.add(layoutTimer!, forMode: .common)
        if !UserDefaults.standard.bool(forKey: "setupComplete") {
            DispatchQueue.main.async { [weak self] in self?.changeSalary() }
        }
    }
    func add(_ menu: NSMenu, _ title: String, _ action: Selector) {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        menu.addItem(item)
    }
    @objc func changeSalary() {
        guard !settingsOpen else { return }
        settingsOpen = true
        defer { settingsOpen = false }
        NSApp.activate(ignoringOtherApps: true)
        let alert = SalarySettingsDialog()
        alert.messageText = "월급·근무 요일·시간 설정"
        alert.informativeText = "선택한 요일과 근무 시간에만 누적됩니다. 저장하면 이번 달 누적액을 새 기준으로 다시 계산합니다."
        let accessory = NSView(frame: NSRect(x: 0, y: 0, width: 350, height: 240))
        let salaryLabel = NSTextField(labelWithString: "월급 (원)")
        salaryLabel.frame = NSRect(x: 0, y: 216, width: 350, height: 20)
        accessory.addSubview(salaryLabel)
        let field = NSTextField(string: Int(model.monthly).formatted(.number.locale(Locale(identifier: "en_US"))))
        salaryInput = field
        field.delegate = self
        field.frame = NSRect(x: 0, y: 184, width: 350, height: 26)
        accessory.addSubview(field)
        let daysLabel = NSTextField(labelWithString: "근무 요일")
        daysLabel.frame = NSRect(x: 0, y: 151, width: 350, height: 20)
        accessory.addSubview(daysLabel)
        let days = [("월", 2), ("화", 3), ("수", 4), ("목", 5), ("금", 6), ("토", 7), ("일", 1)]
        var checkboxes: [NSButton] = []
        for (index, day) in days.enumerated() {
            let checkbox = NSButton(checkboxWithTitle: day.0, target: nil, action: nil)
            checkbox.tag = day.1
            checkbox.state = model.weekdays.contains(day.1) ? .on : .off
            checkbox.frame = NSRect(x: index * 50, y: 118, width: 50, height: 24)
            accessory.addSubview(checkbox)
            checkboxes.append(checkbox)
        }
        let timeLabel = NSTextField(labelWithString: "근무 시간 (24시간 표기)")
        timeLabel.frame = NSRect(x: 0, y: 85, width: 350, height: 20)
        accessory.addSubview(timeLabel)
        let startField = NSTextField(string: workTimeLabel(model.startMinute))
        startField.placeholderString = "09:00"
        startField.frame = NSRect(x: 0, y: 51, width: 145, height: 26)
        accessory.addSubview(startField)
        let separator = NSTextField(labelWithString: "~")
        separator.frame = NSRect(x: 165, y: 54, width: 20, height: 20)
        accessory.addSubview(separator)
        let endField = NSTextField(string: workTimeLabel(model.endMinute))
        endField.placeholderString = "18:00"
        endField.frame = NSRect(x: 205, y: 51, width: 145, height: 26)
        accessory.addSubview(endField)
        let hint = NSTextField(wrappingLabelWithString: "종료가 시작보다 이르면 다음 날 종료됩니다.\n24시간 근무는 00:00 ~ 24:00으로 입력하세요.")
        hint.font = .systemFont(ofSize: 11)
        hint.textColor = .secondaryLabelColor
        hint.frame = NSRect(x: 0, y: 7, width: 350, height: 36)
        accessory.addSubview(hint)
        alert.accessoryView = accessory
        alert.addButton(withTitle: "저장")
        alert.addButton(withTitle: "취소")
        alert.window.initialFirstResponder = field
        while alert.runModal() == .alertFirstButtonReturn {
            let input = field.stringValue.replacingOccurrences(of: ",", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            let selected = Set(checkboxes.filter { $0.state == .on }.map { $0.tag })
            guard let amount = Double(input), amount.isFinite, amount >= 0, amount <= 999_999_999 else {
                let error = NSAlert()
                error.messageText = "월급은 0~999,999,999 사이의 숫자로 입력해주세요."
                error.runModal()
                continue
            }
            guard !selected.isEmpty else {
                let error = NSAlert()
                error.messageText = "근무 요일을 하루 이상 선택해주세요."
                error.runModal()
                continue
            }
            guard let start = parseWorkTime(startField.stringValue),
                  let end = parseWorkTime(endField.stringValue, allowEndOfDay: true), start != end else {
                let error = NSAlert()
                error.messageText = "시작·종료 시간을 09:00처럼 입력해주세요."
                error.informativeText = "시작과 종료는 달라야 합니다. 종료에는 24:00도 사용할 수 있습니다."
                error.runModal()
                continue
            }
            model.startMinute = start
            model.endMinute = end
            UserDefaults.standard.set(start, forKey: "workStartMinute")
            UserDefaults.standard.set(end, forKey: "workEndMinute")
            model.monthly = amount.rounded(.down)
            model.weekdays = selected
            model.now = Date()
            UserDefaults.standard.set(model.monthly, forKey: "monthlySalary")
            UserDefaults.standard.set(selected.sorted(), forKey: "workWeekdays")
            UserDefaults.standard.set(true, forKey: "setupComplete")
            break
        }
    }

    @objc func toggle() { panel.isVisible ? panel.orderOut(nil) : panel.orderFrontRegardless() }
    @objc func showInfo() {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = "급여 누적액 계산 기준"
        alert.informativeText = "월급 × (이번 달 근무 시간 중 지난 시간 ÷ 이번 달 전체 예정 근무 시간)\n\nMac의 시간대를 사용하며, 선택한 요일에 시작하는 근무 시간을 기준으로 계산합니다. 근무 시간 밖에는 금액이 멈춥니다. 야간 근무는 다음 날까지 이어지며 월 경계에서는 해당 월에 속한 시간만 계산합니다. 설정을 변경하면 이번 달 전체 누적액을 다시 계산합니다. 매월 1일에 새로 시작합니다. 실제 지급액이 아닌 시간 비례 추정치입니다.\n\n비둘기 아이콘이 포함된 독립 위젯입니다. 표시창을 드래그해 원하는 위치로 옮길 수 있습니다."
        alert.runModal()
    }
    @objc func quit() { NSApp.terminate(nil) }
}

@main
struct SalaryKkukkuMain {
    static func main() {
        let application = NSApplication.shared
        let delegate = AppDelegate()
        application.delegate = delegate
        withExtendedLifetime(delegate) { application.run() }
    }
}
