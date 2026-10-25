import SwiftUI

struct SleepView: View {
    @ObservedObject var health: HealthStore
    @AppStorage("pulseSleepGoal") private var sleepGoal: Double = 8

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("SLEEP")
                        .font(.caption.bold())
                        .tracking(2)
                        .foregroundStyle(Color.pulseBlue)

                    Text(health.sleep.totalHours.map { String(format: "%.1f", $0) } ?? "—")
                        .font(.system(size: 64, weight: .bold, design: .rounded))

                    Text("horas dormidas")
                        .foregroundStyle(Color.pulseMuted)

                    if let total = health.sleep.totalHours {
                        ProgressView(value: min(1, total / sleepGoal))
                            .tint(Color.pulseBlue)

                        Text("\(Int(min(100, total / sleepGoal * 100)))% del objetivo de \(Int(sleepGoal)) h")
                            .font(.subheadline)
                            .foregroundStyle(Color.pulseMuted)
                    } else {
                        Text("Sin datos de sueño accesibles para el período reciente.")
                            .font(.subheadline)
                            .foregroundStyle(Color.pulseMuted)
                    }
                }
                .padding(22)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.pulseCard, in: RoundedRectangle(cornerRadius: 22))

                HStack(spacing: 12) {
                    sleepTimeCard(
                        title: "Inicio del sueño",
                        date: health.sleep.start,
                        icon: "moon.zzz.fill"
                    )

                    sleepTimeCard(
                        title: "Fin del sueño",
                        date: health.sleep.end,
                        icon: "sun.max.fill"
                    )
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("OBJETIVO DE SUEÑO")
                        .font(.caption.bold())
                        .tracking(1.5)
                        .foregroundStyle(Color.pulseMuted)

                    HStack {
                        Text("\(Int(sleepGoal)) horas")
                            .font(.title3.bold())

                        Spacer()

                        Stepper(
                            "",
                            value: $sleepGoal,
                            in: 5...12,
                            step: 0.5
                        )
                        .labelsHidden()
                    }
                }
                .padding(20)
                .background(Color.pulseCard, in: RoundedRectangle(cornerRadius: 22))
            }
            .padding(20)
        }
        .background(Color.pulseBackground.ignoresSafeArea())
        .navigationTitle("Sueño")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func sleepTimeCard(title: String, date: Date?, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(Color.pulseBlue)

            Text(title)
                .font(.caption)
                .foregroundStyle(Color.pulseMuted)

            Text(date?.pulseTime ?? "—")
                .font(.title3.bold())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Color.pulseCard, in: RoundedRectangle(cornerRadius: 18))
    }
}
