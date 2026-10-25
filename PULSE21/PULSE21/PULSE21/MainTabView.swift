import SwiftUI

struct MainTabView: View {
    @State private var selection: PulseTab = .today
    var body: some View {
        TabView(selection: $selection) {
            TodayView().tabItem { Label("Today", systemImage: PulseTab.today.symbol) }.tag(PulseTab.today)
            StrainView(health: health).tabItem { Label("Strain", systemImage: PulseTab.strain.symbol) }.tag(PulseTab.strain)
            SleepView().tabItem { Label("Sleep", systemImage: PulseTab.sleep.symbol) }.tag(PulseTab.sleep)
            SettingsView().tabItem { Label("Settings", systemImage: PulseTab.settings.symbol) }.tag(PulseTab.settings)
        }.tint(.pulseLime).preferredColorScheme(.dark)
    }
}

struct TodayView: View {
    @EnvironmentObject var health: HealthStore
    @EnvironmentObject var activities: ActivityStore
    private var strain: StrainResult { StrainEngine.score(workouts: health.workouts + activities.manualActivities) }
    private var recovery: RecoveryResult { RecoveryEngine.score(hrv: health.hrv, baselineHRV: nil, restingHR: health.restingHeartRate, baselineRestingHR: nil, sleepHours: health.sleep.totalHours, sleepGoal: UserDefaults.standard.double(forKey: "pulse21.sleepGoal").nonZeroOr(8), recentLoad: nil, calibrationDays: 0) }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    HStack(spacing: 12) {
                        MetricRing(title: "Strain", value: strain.score.map { String(Int($0.rounded())) } ?? "—", progress: strain.score.map { $0 / 21 }, tint: .pulseLime, footnote: strain.score == nil ? "Sin datos" : "de 21")
                        MetricRing(title: "Recovery", value: recovery.score.map { "\($0)%" } ?? "—", progress: recovery.score.map { Double($0) / 100 }, tint: .pulseMint, footnote: recovery.score == nil ? "Calibrando" : "estimada")
                        MetricRing(title: "Sleep", value: health.sleep.totalHours.map { String(format: "%.1fh", $0) } ?? "—", progress: health.sleep.totalHours.map { min(1, $0 / UserDefaults.standard.double(forKey: "pulse21.sleepGoal").nonZeroOr(8)) }, tint: .pulseBlue, footnote: "horas dormidas")
                    }.padding(.top, 2)
                    SectionHeader(title: "Your metrics", trailing: "HOY")
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        MetricCard(title: "Frecuencia en reposo", value: health.restingHeartRate.map { String(Int($0.rounded())) } ?? "—", unit: health.restingHeartRate == nil ? "Sin datos" : "bpm", symbol: "heart.fill", tint: .pulseMint)
                        MetricCard(title: "Variabilidad cardíaca", value: health.hrv.map { String(Int($0.rounded())) } ?? "—", unit: health.hrv == nil ? "Sin datos" : "ms", symbol: "waveform.path.ecg", tint: .pulseBlue)
                        MetricCard(title: "Pasos", value: health.steps.map { Int($0).formatted() } ?? "—", unit: health.steps == nil ? "Sin datos" : "pasos", symbol: "figure.walk", tint: .pulseLime)
                        MetricCard(title: "Energía activa", value: health.activeEnergy.map { Int($0).formatted() } ?? "—", unit: health.activeEnergy == nil ? "Sin datos" : "kcal", symbol: "flame.fill", tint: .orange)
                    }
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(title: "Último sueño")
                        HStack(spacing: 14) {
                            Image(systemName: "moon.stars.fill").font(.title2).foregroundStyle(.pulseBlue).frame(width: 48, height: 48).background(Color.pulseBlue.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
                            VStack(alignment: .leading, spacing: 4) {
                                Text(health.sleep.totalHours.map { String(format: "%.1f horas", $0) } ?? "Sin datos de sueño").font(.headline)
                                Text(sleepWindow).font(.caption).foregroundStyle(Color.pulseMuted)
                            }
                            Spacer()
                        }.padding(16).background(Color.pulseCard, in: RoundedRectangle(cornerRadius: 18))
                    }
                    VStack(alignment: .leading, spacing: 10) {
                        SectionHeader(title: "Actividad reciente")
                        if let latest = (health.workouts + activities.manualActivities).sorted(by: { $0.start > $1.start }).first {
                            HStack { Image(systemName: "figure.run").foregroundStyle(.pulseLime); VStack(alignment: .leading, spacing: 3) { Text(latest.title).font(.headline); Text(latest.start.formatted(date: .abbreviated, time: .shortened)).font(.caption).foregroundStyle(Color.pulseMuted) }; Spacer(); Text("\(Int(latest.durationMinutes)) min").font(.subheadline.monospacedDigit()) }.padding(16).background(Color.pulseCard, in: RoundedRectangle(cornerRadius: 18))
                        } else { emptyCard("Todavía no hay entrenamientos disponibles.") }
                    }
                    HStack(spacing: 10) { Circle().fill(health.lastUpdated == nil ? .orange : .pulseMint).frame(width: 7, height: 7); Text(health.lastUpdated.map { "Apple Salud · actualizado \($0.pulseTime)" } ?? "Apple Salud · aún no sincronizado").font(.caption).foregroundStyle(Color.pulseMuted); Spacer(); Button { Task { await health.refresh() } } label: { Image(systemName: "arrow.clockwise").foregroundStyle(.pulseLime) }.disabled(health.isLoading) }
                    if let error = health.errorMessage { Text(error).font(.caption).foregroundStyle(.orange) }
                }.padding(20)
            }.background(Color.pulseBackground).toolbar(.hidden, for: .navigationBar).refreshable { await health.refresh() }
        }
    }
    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 5) { Text("PULSE 21").font(.system(size: 24, weight: .black, design: .rounded)).tracking(1.5); Text(Date().pulseDate).font(.subheadline).foregroundStyle(Color.pulseMuted) }
            Spacer()
            Button { Task { await health.requestAccessAndSync() } } label: { Image(systemName: health.isLoading ? "hourglass" : "arrow.triangle.2.circlepath").font(.headline).foregroundStyle(.black).frame(width: 42, height: 42).background(Color.pulseLime, in: Circle()) }.accessibilityLabel("Conectar o sincronizar Apple Salud")
        }
    }
    private var sleepWindow: String {
        guard let start = health.sleep.start, let end = health.sleep.end else { return "Apple Salud no ha proporcionado horarios" }
        return "\(start.pulseTime) – \(end.pulseTime)"
    }
    private func emptyCard(_ message: String) -> some View { Text(message).font(.subheadline).foregroundStyle(Color.pulseMuted).frame(maxWidth: .infinity, alignment: .leading).padding(16).background(Color.pulseCard, in: RoundedRectangle(cornerRadius: 18)) }
}

private extension Double { func nonZeroOr(_ fallback: Double) -> Double { self > 0 ? self : fallback } }
