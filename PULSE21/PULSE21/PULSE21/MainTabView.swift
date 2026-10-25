
import SwiftUI

struct MainTabView: View {
    @StateObject private var health = HealthStore()

    var body: some View {
        TabView {
            HomeView(health: health)
                .tabItem {
                    Label("Today", systemImage: "house.fill")
                }

            SleepView(health: health)
                .tabItem {
                    Label("Sleep", systemImage: "moon.stars.fill")
                }

            StrainView(health: health)
                .tabItem {
                    Label("Strain", systemImage: "figure.run")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .tint(Color.pulseBlue)
    }
}

private struct HomeView: View {
    @ObservedObject var health: HealthStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("PULSE 21")
                        .font(.caption.bold())
                        .tracking(2)
                        .foregroundStyle(Color.pulseBlue)

                    Text("Tu día")
                        .font(.largeTitle.bold())

                    Text(Date.now.formatted(
                        .dateTime.weekday(.wide).day().month(.wide)
                    ))
                    .foregroundStyle(Color.pulseMuted)
                }

                HStack(spacing: 12) {
                    metricCard(
                        title: "FRECUENCIA CARDÍACA",
                        value: health.heartRate.map {
                            "\(Int($0.rounded()))"
                        } ?? "—",
                        unit: "lpm",
                        symbol: "heart.fill"
                    )

                    metricCard(
                        title: "PASOS",
                        value: health.steps.map {
                            "\(Int($0.rounded()))"
                        } ?? "—",
                        unit: "pasos",
                        symbol: "figure.walk"
                    )
                }

                HStack(spacing: 12) {
                    metricCard(
                        title: "SUEÑO",
                        value: health.sleep.totalHours.map {
                            String(format: "%.1f", $0)
                        } ?? "—",
                        unit: "horas",
                        symbol: "moon.stars.fill"
                    )

                    metricCard(
                        title: "ENERGÍA ACTIVA",
                        value: health.activeEnergy.map {
                            "\(Int($0.rounded()))"
                        } ?? "—",
                        unit: "kcal",
                        symbol: "flame.fill"
                    )
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("DATOS DE APPLE SALUD")
                        .font(.caption.bold())
                        .tracking(1.3)
                        .foregroundStyle(Color.pulseMuted)

                    Text("Los valores se muestran cuando PULSE 21 tiene permiso para acceder a los datos correspondientes.")
                        .font(.subheadline)
                        .foregroundStyle(Color.pulseMuted)

                    Button {
                        health.refresh()
                    } label: {
                        Label("Actualizar datos", systemImage: "arrow.clockwise")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                Color.pulseBlue.opacity(0.15),
                                in: RoundedRectangle(cornerRadius: 14)
                            )
                    }
                    .buttonStyle(.plain)
                }
                .padding(18)
                .background(
                    Color.pulseCard,
                    in: RoundedRectangle(cornerRadius: 20)
                )
            }
            .padding(20)
        }
        .background(Color.pulseBackground.ignoresSafeArea())
    }

    private func metricCard(
        title: String,
        value: String,
        unit: String,
        symbol: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(Color.pulseBlue)

            Text(title)
                .font(.caption2.bold())
                .foregroundStyle(Color.pulseMuted)
                .fixedSize(horizontal: false, vertical: true)

            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.7)
                .lineLimit(1)

            Text(unit)
                .font(.caption)
                .foregroundStyle(Color.pulseMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            Color.pulseCard,
            in: RoundedRectangle(cornerRadius: 20)
        )
    }
}

#Preview {
    MainTabView()
}
