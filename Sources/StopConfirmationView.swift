import SwiftUI

struct StopConfirmationView: View {
    @ObservedObject var model: TimerModel
    var body: some View {
        VStack(spacing: 22) {
            Spacer()
            Image(systemName: "stop.circle").font(.system(size: 48, weight: .light))
                .foregroundColor(Color(red: 1, green: 0.55, blue: 0.5))
            Text("Stop the timer?").font(.system(size: 27, weight: .semibold))
            Text("Are you sure? This ends the current timer and returns to a paused 52-minute focus timer.")
                .font(.system(size: 15)).multilineTextAlignment(.center).foregroundColor(.secondary)
            Text("Unfinished focus time won’t count. Your completed session history stays saved. The timer continues until you confirm.")
                .font(.system(size: 12)).multilineTextAlignment(.center).foregroundColor(.secondary)
            VStack(spacing: 12) {
                Button("Yes, stop timer", action: model.confirmStop)
                    .buttonStyle(.borderedProminent).tint(Color(red: 0.75, green: 0.22, blue: 0.19))
                Button("Keep timer", action: model.cancelStop)
                    .keyboardShortcut(.cancelAction).buttonStyle(.bordered)
            }
            Spacer()
        }.padding(34).frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
