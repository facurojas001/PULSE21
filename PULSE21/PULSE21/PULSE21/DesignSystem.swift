import SwiftUI

extension Color {
    static let pulseBackground = Color(red: 0.035, green: 0.043, blue: 0.05)
    static let pulseCard = Color(red: 0.085, green: 0.095, blue: 0.105)
    static let pulseLime = Color(red: 0.72, green: 0.98, blue: 0.20)
    static let pulseMint = Color(red: 0.20, green: 0.88, blue: 0.68)
    static let pulseBlue = Color(red: 0.40, green: 0.70, blue: 1.0)
    static let pulseMuted = Color.white.opacity(0.55)
}

struct MetricRing: View {
    let title: String
    let value: String
    let progress: Double?
    let tint: Color
    let footnote: String
    var body: some View {
        VStack(spacing: 9) {
            ZStack {
                Circle().stroke(Color.white.opacity(0.09), lineWidth: 6)
                if let progress {
                    Circle().trim(from: 0, to: max(0, min(1, progress))).stroke(tint, style: StrokeStyle(lineWidth: 6, lineCap: .round)).rotationEffect(.degrees(-90))
                }
                VStack(spacing: 2) {
                    Text(value).font(.system(size: 20, weight: .semibold, design: .rounded)).minimumScaleFactor(0.6).lineLimit(1)
                    Text(title.uppercased()).font(.system(size: 8, weight: .bold, design: .rounded)).tracking(0.8).foregroundStyle(Color.pulseMuted)
                }
            }.frame(maxWidth: .infinity).aspectRatio(1, contentMode: .fit)
            Text(footnote).font(.system(size: 10, weight: .medium)).foregroundStyle(Color.pulseMuted).lineLimit(1).minimumScaleFactor(0.75)
        }
    }
}

struct SectionHeader: View {
    let title: String
    var trailing: String? = nil
    var body: some View { HStack { Text(title).font(.system(size: 18, weight: .semibold)); Spacer(); if let trailing { Text(trailing).font(.caption).foregroundStyle(Color.pulseMuted) } } }
}

struct MetricCard: View {
    let title: String
    let value: String
    let unit: String
    let symbol: String
    let tint: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack { Image(systemName: symbol).foregroundStyle(tint); Spacer() }
            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .firstTextBaseline, spacing: 4) { Text(value).font(.system(size: 26, weight: .semibold, design: .rounded)).minimumScaleFactor(0.7).lineLimit(1); Text(unit).font(.caption).foregroundStyle(Color.pulseMuted) }
                Text(title).font(.caption).foregroundStyle(Color.pulseMuted)
            }
        }.padding(15).frame(maxWidth: .infinity, alignment: .leading).background(Color.pulseCard, in: RoundedRectangle(cornerRadius: 18))
    }
}

extension Date {
    var pulseTime: String { formatted(date: .omitted, time: .shortened) }
    var pulseDate: String { formatted(.dateTime.weekday(.wide).month(.abbreviated).day()) }
}
