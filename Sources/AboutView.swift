import SwiftUI

struct AboutView: View {
    @ObservedObject var model: TimerModel
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 5) {
                Text("About 5217").font(.system(size: 22, weight: .semibold))
                Text("Version \(AppVersion.current) · Build \(AppVersion.build)")
                    .font(.system(size: 12)).foregroundColor(.secondary)
                    .accessibilityLabel("Current version \(AppVersion.current), build \(AppVersion.build)")
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Focus fully. Rest genuinely.").font(.system(size: 18, weight: .medium))
                    Text("Give one task 52 minutes of focused attention, then take 17 minutes away from work. Skip multitasking during focus; walk, stretch or simply unwind during the break.")
                    Text("The rhythm comes from DeskTime’s observations of its most productive users. It’s a useful pattern to try, not a guaranteed formula: the aim is sustainable attention and regular recovery, rather than longer hours.")
                    Divider()
                    Text("READ MORE").font(.system(size: 10, weight: .semibold)).tracking(1)
                    article("The Muse · The 52/17 rule", "https://www.themuse.com/advice/the-rule-of-52-and-17-its-random-but-it-ups-your-productivity")
                    article("Focusmeter · A practical guide", "https://focusmeter.app/guides/52-17-rule.html")
                    article("The Atlantic · Why breaks matter", "https://www.theatlantic.com/business/archive/2014/09/science-tells-you-how-many-minutes-should-you-take-a-break-for-work-17/380369/")
                    article("Optima Results Coaching · Focus and presence", "https://optimaresultscoaching.com/the-5217-rule-for-productivity/")
                    article("FocusTribe · 52/17 timer", "https://focustribe.in/52-17-timer")
                    Divider()
                    Text("Built by Arjun Sabharwal")
                        .font(.system(size: 12, weight: .medium)).foregroundColor(.secondary)
                }
                .font(.system(size: 14)).foregroundColor(.secondary).lineSpacing(4)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }.padding(24).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
    private func article(_ title: String, _ url: String) -> some View {
        Link(title + " ↗", destination: URL(string: url)!).font(.system(size: 13))
    }
}
