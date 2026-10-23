import AppKit
import SwiftUI
import UserNotifications

enum AppScreen { case timer, settings, history, confirmStop }

final class TimerModel: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    @Published private(set) var engine: TimerEngine
    @Published private(set) var now = Date()
    @Published private(set) var notificationStatus: UNAuthorizationStatus = .notDetermined
    @Published private(set) var notice: String?
    @Published private(set) var quotes: QuoteRotation
    @Published private(set) var quoteLoading = false
    @Published private(set) var quoteStatus = "Curated quotes"
    @Published private(set) var stopControl = StopControl()
    @Published var screen: AppScreen = .timer { didSet { onLayoutChange?() } }
    @Published var quotesCollapsed = false { didSet { onLayoutChange?() } }
    var windowHeight: CGFloat { screen == .timer && quotesCollapsed ? 674 : 785 }
    var onLayoutChange: (() -> Void)?
    @Published var settingsTab: SettingsTab = .sounds
    @Published var historyWeek = Date()
    @Published private(set) var focusSessions: [FocusSession] = []
    @Published private(set) var historyError: String?
    private var historyStore: FocusHistoryStore?
    let sounds: SoundController
    var onUpdate: (() -> Void)?
    var onShow: (() -> Void)?
    var onSilenceAlert: (() -> Void)?
    var onAlert: ((Phase) -> Void)?
    private var timer: Timer?
    private var activity: NSObjectProtocol?
    private var delivery = NotificationDeliveryState()
    private let center = UNUserNotificationCenter.current()
    private let saveURL: URL
    private let onlineQuotes: OnlineQuoteService

    init(paths: AppPaths = .standard) {
        saveURL = paths.timer
        sounds = SoundController(paths: paths)
        onlineQuotes = OnlineQuoteService(directory: paths.directory)
        var restored = LocalStorage.load(TimerEngine.self, from: paths.timer, limit: 262_144) ?? TimerEngine()
        restored.validate(at: Date())
        engine = restored
        quotes = QuoteRotation(phase: .focus, now: Date())
        super.init()
        sounds.onSelectionChange = { [weak self] in
            self?.cancelScheduled()
            self?.scheduleBoundary()
        }
        do {
            historyStore = try FocusHistoryStore(directory: paths.directory.appendingPathComponent("FocusHistory", isDirectory: true))
            recordHistory(engine.completions)
        } catch {
            historyError = "History could not be read. Existing files have been preserved."
        }
        center.delegate = self
        center.removeAllPendingNotificationRequests()
        recordHistory(engine.advance(to: now))
        quotes.select(engine.phase, at: now)
        if let feed = onlineQuotes.cached {
            quotes.useOnline(feed, at: now)
            quoteStatus = "Saved online quotes"
        }
        refreshNotificationStatus()
        updateActivity()
        timer = Timer(timeInterval: 0.2, repeats: true) { [weak self] _ in self?.tick() }
        RunLoop.main.add(timer!, forMode: .common)
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(woke), name: NSWorkspace.didWakeNotification, object: nil)
        save()
        if onlineQuotes.shouldRefreshAutomatically(at: now) { refreshOnlineQuotes() }
    }

    var secondsLeft: Int { engine.secondsLeft(at: now) }
    var clockText: String { String(format: "%02d:%02d", secondsLeft / 60, secondsLeft % 60) }
    var progress: Double { min(1, max(0, Double(secondsLeft) / engine.phase.seconds)) }
    var sessions: Int { engine.sessionsToday(at: now) }
    var hasStarted: Bool { engine.isRunning || engine.remaining < engine.phase.seconds }

    func nextQuote() {
        quotes.select(engine.phase, at: Date())
        quotes.refresh(at: Date())
    }

    func refreshOnlineQuotes() {
        guard !quoteLoading else { return }
        guard onlineQuotes.mayRequest else {
            quoteStatus = "Wait a minute before updating again"
            return
        }
        quoteLoading = true
        quoteStatus = "Getting fresh quotes…"
        onlineQuotes.fetch { [weak self] result in
            guard let self else { return }
            self.quoteLoading = false
            switch result {
            case .success(let feed):
                self.quotes.useOnline(feed, at: Date())
                self.quoteStatus = "\(feed.count) online quotes saved"
            case .failure:
                self.quoteStatus = self.onlineQuotes.cached == nil ? "Offline · curated quotes ready" : "Offline · saved quotes ready"
            }
        }
    }

    func toggle() {
        tick()
        cancelScheduled()
        if engine.isRunning {
            engine.pause(at: now)
        } else {
            engine.start(at: now)
            requestNotifications()
        }
        changed()
    }

    func reset() {
        cancelScheduled()
        engine.reset()
        changed()
    }

    func skip() {
        tick()
        cancelScheduled()
        engine.skip(at: now)
        changed()
    }

    func setSound(_ value: Bool) {
        cancelScheduled()
        engine.soundEnabled = value
        changed()
    }

    func pressStop() {
        tick()
        sounds.stop()
        onSilenceAlert?()
        center.removeAllDeliveredNotifications()
        if stopControl.press() == .requestConfirmation { screen = .confirmStop }
    }

    func cancelStop() {
        stopControl.reset()
        screen = .timer
    }

    func confirmStop() {
        guard screen == .confirmStop else { return }
        tick()
        cancelScheduled()
        sounds.stop()
        onSilenceAlert?()
        center.removeAllDeliveredNotifications()
        engine.phase = .focus
        engine.reset()
        screen = .timer
        changed()
    }

    func testAlert() {
        if engine.soundEnabled { sounds.playSelected() }
        onAlert?(.focus)
    }

    private func tick() {
        now = Date()
        let events = engine.advance(to: now)
        if !events.isEmpty { recordHistory(events) }
        quotes.select(engine.phase, at: now)
        quotes.advance(to: now)
        if onlineQuotes.shouldRefreshAutomatically(at: now) { refreshOnlineQuotes() }
        if !events.isEmpty {
            // macOS delivers the scheduled notification. Fall back to an app chime
            // when notifications are unavailable, and avoid replaying old alarms.
            if let last = events.last, now.timeIntervalSince(last.date) < 5 {
                // App-owned playback can be stopped immediately, including long tones.
                // Scheduled macOS banners are silent to avoid an uncontrollable second player.
                if engine.soundEnabled { sounds.playSelected() }
                if !notificationsAllowed || delivery.failed { onAlert?(last.phase) }
            }
            delivery.cancel()
            changed()
        }
        onUpdate?()
    }

    @objc private func woke() {
        tick()
        refreshNotificationStatus()
    }

    private var notificationsAllowed: Bool {
        notificationStatus == .authorized || notificationStatus == .provisional
    }

    func refreshNotificationStatus() {
        center.getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.notificationStatus = settings.authorizationStatus
                self.cancelScheduled()
                self.scheduleBoundary()
            }
        }
    }

    private func requestNotifications() {
        center.requestAuthorization(options: [.alert, .sound]) { _, error in
            DispatchQueue.main.async {
                if error != nil { self.notice = "Built-in alerts are active. Enable system notifications in Settings." }
                self.refreshNotificationStatus()
            }
        }
    }

    private func scheduleBoundary() {
        guard notificationsAllowed, let deadline = engine.deadline else { return }
        let content = UNMutableNotificationContent()
        content.title = engine.phase == .focus ? "Focus complete. Time for a break." : "Break complete. Ready to focus?"
        content.body = engine.phase == .focus ? "Your 17-minute break has started. Step away and recharge." : "Your next 52-minute focus session has started. One thing at a time."
        let id = delivery.begin()
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, deadline.timeIntervalSinceNow), repeats: false)
        center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger)) { error in
            DispatchQueue.main.async {
                guard self.delivery.complete(id: id, failed: error != nil) else {
                    self.center.removePendingNotificationRequests(withIdentifiers: [id])
                    return
                }
                if error != nil { self.notice = "Built-in alerts are active. Enable system notifications in Settings." }
            }
        }
    }

    private func cancelScheduled() {
        if let id = delivery.cancel() { center.removePendingNotificationRequests(withIdentifiers: [id]) }
    }

    private func changed() {
        stopControl.reset()
        quotes.select(engine.phase, at: Date())
        save()
        updateActivity()
        scheduleBoundary()
        onUpdate?()
    }

    private func updateActivity() {
        if engine.isRunning, activity == nil {
            activity = ProcessInfo.processInfo.beginActivity(options: [.userInitiated, .idleSystemSleepDisabled], reason: "Running a 5217 focus timer")
        } else if !engine.isRunning, let current = activity {
            ProcessInfo.processInfo.endActivity(current)
            activity = nil
        }
    }

    private func save() {
        recordHistory([]) // Retry any archive writes that previously failed.
        do {
            try LocalStorage.save(engine, to: saveURL)
        } catch {
            notice = "Your timer could not be saved. It will still work until you quit."
        }
    }

    private func recordHistory(_ events: [Completion]) {
        guard let store = historyStore else { return }
        do {
            try store.record(events)
            historyError = nil
        } catch {
            historyError = "History could not be saved. Keep the app open and check available disk space and file permissions."
        }
        focusSessions = store.sessions
    }

    func shutdown() {
        tick()
        sounds.stop()
        delivery.cancel()
        if engine.isRunning { engine.pause(at: Date()) }
        center.removeAllPendingNotificationRequests()
        save()
        updateActivity()
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .list])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        DispatchQueue.main.async { self.onShow?() }
        completionHandler()
    }
}
