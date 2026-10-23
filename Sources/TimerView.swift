import SwiftUI
import AppKit

private let ink = Color(red: 0.075, green: 0.09, blue: 0.085)
private let muted = Color(red: 0.57, green: 0.61, blue: 0.58)
private let lime = Color(red: 0.82, green: 0.96, blue: 0.44)
private let sky = Color(red: 0.53, green: 0.81, blue: 0.96)

struct TimerView: View {
    @ObservedObject var model: TimerModel
    @ObservedObject var sounds: SoundController
    private var accent: Color { model.engine.phase == .focus ? lime : sky }

    var body: some View {
        Group {
            switch model.screen {
            case .timer: timerContent
            case .settings: SettingsView(model: model, sound: sounds)
            case .history: HistoryView(model: model)
            case .confirmStop: StopConfirmationView(model: model)
            }
        }
        .frame(width: 460, height: model.windowHeight)
        .background(ink)
        .preferredColorScheme(.dark)
        .onExitCommand { model.cancelStop() }
    }

    private var timerContent: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                HStack(spacing: 0) {
                    Text("52").foregroundColor(lime)
                    Text("17").foregroundColor(.white)
                }
                .font(.system(size: 29, weight: .heavy, design: .rounded))
                Spacer()
                Button { model.screen = .settings } label: {
                    Image(systemName: "gearshape").font(.system(size: 16)).foregroundColor(muted)
                        .frame(width: 28, height: 28).contentShape(Rectangle())
                }
                .buttonStyle(.plain).help("Settings (⌘,)").accessibilityLabel("Open sound settings")
            }
            .padding(.bottom, 22)

            HStack(spacing: 5) {
                phaseLabel("Focus", minutes: "52", active: model.engine.phase == .focus, color: lime)
                Image(systemName: "arrow.right").font(.system(size: 10, weight: .bold)).foregroundColor(muted).padding(.horizontal, 7)
                phaseLabel("Break", minutes: "17", active: model.engine.phase == .rest, color: sky)
            }

            ZStack {
                Circle().stroke(Color.white.opacity(0.055), lineWidth: 7)
                Circle().trim(from: 0, to: model.progress)
                    .stroke(accent, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 12) {
                    Text(model.engine.phase == .focus ? "TIME TO FOCUS" : "TAKE A BREATHER")
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .tracking(2.8).foregroundColor(accent)
                    Text(model.clockText)
                        .font(.system(size: 66, weight: .light, design: .rounded)).monospacedDigit()
                        .tracking(-3).foregroundColor(.white)
                        .contentTransition(.identity)
                        .accessibilityLabel("\(model.secondsLeft / 60) minutes, \(model.secondsLeft % 60) seconds remaining")
                    Text(model.engine.isRunning ? "remaining" : model.hasStarted ? "paused · take your time" : "ready when you are")
                        .font(.system(size: 12)).foregroundColor(muted)
                }
            }
            .frame(width: 244, height: 244)
            .padding(.top, 22).padding(.bottom, 22)

            quoteCard

            HStack(spacing: 10) {
                Button(action: model.reset) {
                    Image(systemName: "arrow.counterclockwise").font(.system(size: 17, weight: .medium))
                        .frame(width: 49, height: 49)
                        .foregroundColor(.white.opacity(0.85)).background(Color.white.opacity(0.065), in: RoundedRectangle(cornerRadius: 14))
                }.buttonStyle(.plain).help("Reset this \(model.engine.phase.title.lowercased()) timer (⌘R)")
                    .accessibilityLabel("Reset timer")
                Button(action: model.toggle) {
                    HStack(spacing: 9) {
                        Image(systemName: model.engine.isRunning ? "pause.fill" : "play.fill").font(.system(size: 12, weight: .bold))
                        Text(model.engine.isRunning ? "Pause" : model.hasStarted ? "Resume \(model.engine.phase.title.lowercased())" : "Start \(model.engine.phase.title.lowercased())")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .frame(maxWidth: .infinity).frame(height: 49)
                    .foregroundColor(ink).background(accent, in: RoundedRectangle(cornerRadius: 14))
                }.buttonStyle(.plain).keyboardShortcut(.space, modifiers: [])
                Button(action: model.skip) {
                    Image(systemName: "forward.end.fill").font(.system(size: 16, weight: .medium))
                        .frame(width: 49, height: 49)
                        .foregroundColor(.white.opacity(0.85)).background(Color.white.opacity(0.065), in: RoundedRectangle(cornerRadius: 14))
                }.buttonStyle(.plain).help("Skip to \(model.engine.phase.next.title.lowercased()) (⌘→)")
                    .accessibilityLabel("Skip to \(model.engine.phase.next.title.lowercased())")
                Button(action: model.pressStop) {
                    Image(systemName: "stop.fill").font(.system(size: 15, weight: .medium))
                        .frame(width: 49, height: 49)
                        .foregroundColor(Color(red: 1, green: 0.55, blue: 0.5))
                        .background(Color.white.opacity(0.065), in: RoundedRectangle(cornerRadius: 14))
                }.buttonStyle(.plain)
                    .help(model.stopControl.armed ? "Click again to confirm stopping the timer" : "Silence alerts; click again to stop the timer")
                    .accessibilityLabel(model.stopControl.armed ? "Stop timer" : "Silence alert")
                    .accessibilityValue(sounds.isPlaying ? "Sound playing" : "Sound silent")
            }.padding(.top, 18)

            HStack(spacing: 5) {
                Image(systemName: model.stopControl.armed ? "speaker.slash" : "repeat").font(.system(size: 10))
                Text(model.stopControl.armed ? "Sound stopped · Press Stop again to end the timer" : "52 min focus · 17 min break · repeats automatically")
                    .font(.system(size: 10))
            }.foregroundColor(muted).padding(.top, 13)

            Rectangle().fill(Color.white.opacity(0.08)).frame(height: 1).padding(.top, 18).padding(.bottom, 17)
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("TODAY").font(.system(size: 9, weight: .semibold, design: .monospaced)).tracking(1.5).foregroundColor(muted)
                    HStack(alignment: .firstTextBaseline, spacing: 5) {
                        Text("\(model.sessions)").font(.system(size: 19, weight: .semibold)).foregroundColor(.white)
                        Text(model.sessions == 1 ? "session" : "sessions").font(.system(size: 11)).foregroundColor(muted)
                        Text("·  \(model.sessions * 52) min focused").font(.system(size: 11)).foregroundColor(muted)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 10) {
                    Button { model.setSound(!model.engine.soundEnabled) } label: {
                        HStack(spacing: 6) {
                            Image(systemName: model.engine.soundEnabled ? "speaker.wave.2" : "speaker.slash")
                            Text(model.engine.soundEnabled ? "Sound on" : "Sound off")
                        }.font(.system(size: 11)).foregroundColor(model.engine.soundEnabled ? accent : muted)
                    }.buttonStyle(.plain).help("Toggle transition sounds")
                        .accessibilityLabel(model.engine.soundEnabled ? "Turn sound off" : "Turn sound on")
                    Button {
                        model.historyWeek = Date()
                        model.screen = .history
                    } label: {
                        Label("History", systemImage: "clock.arrow.circlepath").font(.system(size: 11))
                    }.buttonStyle(.plain).foregroundColor(muted)
                        .help("View focus session history").accessibilityLabel("Focus session history")
                }

            }
            if model.notificationStatus == .denied {
                Button("Notifications are off. Open System Settings ↗") {
                    NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.Notifications-Settings.extension")!)
                }.font(.system(size: 10)).buttonStyle(.plain).foregroundColor(sky).padding(.top, 15)
            } else if let notice = model.notice {
                Text(notice).font(.system(size: 10)).foregroundColor(sky).lineLimit(2).padding(.top, 13)
            } else {
                Text("To quit: menu bar → Quit 5217, or right-click the Dock icon → Quit.")
                    .font(.system(size: 10)).foregroundColor(muted.opacity(0.7)).padding(.top, 17).offset(y: 8)
            }
        }
        .padding(.horizontal, 34).padding(.top, 21).padding(.bottom, 22)
        .frame(width: 460, height: model.windowHeight)
        .background(ink)
        .preferredColorScheme(.dark)
    }

    private var quoteCard: some View {
        Group {
            if model.quotesCollapsed {
                HStack {
                    Text("QUOTES").font(.system(size: 9, weight: .semibold, design: .monospaced))
                        .tracking(1.1).foregroundColor(accent)
                    Spacer()
                    Button { model.quotesCollapsed = false } label: {
                        Label("Show quotes", systemImage: "chevron.down")
                            .font(.system(size: 10, weight: .medium)).foregroundColor(accent)
                    }.buttonStyle(.plain).accessibilityLabel("Show quotes")
                        .help("Expand the quote section")
                }
                .frame(height: 24)
                .padding(.horizontal, 15).padding(.vertical, 12)
                .background(accent.opacity(0.045), in: RoundedRectangle(cornerRadius: 15))
                .overlay(RoundedRectangle(cornerRadius: 15).stroke(accent.opacity(0.12), lineWidth: 1))
            } else {
                expandedQuoteCard
            }
        }
    }

    private var expandedQuoteCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(model.engine.phase == .focus ? "A MOMENT OF FOCUS" : "A MOMENT OF REST")
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .tracking(1.1).foregroundColor(accent)
                Spacer()
                Button(action: model.nextQuote) {
                    Label("Next quote", systemImage: "arrow.clockwise")
                        .font(.system(size: 10, weight: .medium)).foregroundColor(accent)
                        .padding(.vertical, 4).padding(.leading, 5)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("Show another quote (⌘N). Quotes also change every 60 seconds.")
                .accessibilityLabel("Next quote")
                Button { model.refreshOnlineQuotes() } label: {
                    Image(systemName: model.quoteLoading ? "hourglass" : "arrow.down.circle")
                        .font(.system(size: 13)).foregroundColor(accent)
                        .frame(width: 24, height: 24).contentShape(Rectangle())
                }
                .buttonStyle(.plain).disabled(model.quoteLoading)
                .help("Get fresh online quotes. \(model.quoteStatus)")
                .accessibilityLabel("Update online quotes")
                Button { model.quotesCollapsed = true } label: {
                    Image(systemName: "chevron.up").font(.system(size: 11, weight: .semibold))
                        .foregroundColor(muted).frame(width: 22, height: 24).contentShape(Rectangle())
                }.buttonStyle(.plain).help("Hide quotes")
                    .accessibilityLabel("Hide quotes")
            }
            Text("“\(model.quotes.quote.text)”")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white.opacity(0.95))
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, minHeight: 58, alignment: .leading)
                .accessibilityLabel(model.quotes.quote.text)
            HStack {
                if let url = URL(string: model.quotes.quote.source) {
                    Link(destination: url) {
                        Text("— \(model.quotes.quote.author) ↗")
                            .font(.system(size: 10)).foregroundColor(muted)
                    }
                    .help(model.quotes.quote.provider == nil ? "Read source: \(model.quotes.quote.work)" : "Attribution supplied by ZenQuotes; original work not provided")
                    .accessibilityLabel("Read quote source by \(model.quotes.quote.author)")
                }
                Spacer()
                Text("\(model.quotes.index + 1)/\(model.quotes.count) · 60s")
                    .font(.system(size: 9, design: .monospaced)).foregroundColor(muted)
            }
            HStack(spacing: 4) {
                Text(model.quoteStatus).lineLimit(1).help(model.quoteStatus)
                Spacer(minLength: 4)
                Link("Quotes by ZenQuotes ↗", destination: URL(string: "https://zenquotes.io/")!)
                    .help("Online inspirational quotes provided by ZenQuotes API")
            }
            .font(.system(size: 9)).foregroundColor(muted.opacity(0.9))
        }
        .padding(.horizontal, 15).padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(accent.opacity(0.045), in: RoundedRectangle(cornerRadius: 15))
        .overlay(RoundedRectangle(cornerRadius: 15).stroke(accent.opacity(0.12), lineWidth: 1))
    }

    private func phaseLabel(_ label: String, minutes: String, active: Bool, color: Color) -> some View {
        HStack(spacing: 6) {
            Text(minutes).font(.system(size: 13, weight: .bold, design: .rounded))
            Text(label).font(.system(size: 12, weight: .medium))
        }
        .foregroundColor(active ? color : muted)
        .padding(.horizontal, 19).padding(.vertical, 10)
        .background(active ? color.opacity(0.09) : Color.clear, in: Capsule())
        .overlay(Capsule().stroke(active ? color.opacity(0.15) : Color.white.opacity(0.06), lineWidth: 1))
    }
}

struct TransitionAlert: View {
    let completed: Phase
    let dismiss: () -> Void
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            Image(systemName: completed == .focus ? "cup.and.saucer.fill" : "scope")
                .font(.system(size: 24)).foregroundColor(completed == .focus ? sky : lime)
                .padding(.top, 5)
            VStack(alignment: .leading, spacing: 7) {
                Text("5217").font(.system(size: 10, weight: .bold)).foregroundColor(muted)
                Text(completed == .focus ? "Focus complete. Take a break." : "Break complete. Time to focus.")
                    .font(.system(size: 14, weight: .semibold)).foregroundColor(.white)
                Text(completed == .focus ? "Your 17-minute break is starting." : "Your 52-minute focus session is starting.")
                    .font(.system(size: 11)).foregroundColor(muted)
            }
            Spacer(minLength: 0)
            Button(action: dismiss) { Image(systemName: "xmark").font(.system(size: 10, weight: .bold)).foregroundColor(muted) }
                .buttonStyle(.plain).accessibilityLabel("Dismiss alert")
        }
        .padding(20).frame(width: 360, height: 132)
        .background(ink, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.15), lineWidth: 1))
        .preferredColorScheme(.dark)
    }
}
