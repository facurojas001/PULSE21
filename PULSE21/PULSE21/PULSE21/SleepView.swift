import SwiftUI

struct SleepView: View {
    @EnvironmentObject var health: HealthStore
    @AppStorage("pulse21.sleepGoal") private var sleepGoal = 8.0
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 8) { Text("SLEEP").font(.caption.bold()).tracking(2).foregroundStyle(.pulseBlue); Text(health.sleep.totalHours.map { String(format: "%.1f", $0) } ?? "—").font(.system(size: 64, weight: .bold, design: .rounded)); Text("horas dormidas").foregroundStyle(Color.pulseMuted); if let total = health.sleep.totalHours { ProgressView(value: min(1, total / sleepGoal)).tint(.pulseBlue); Text("\(Int(min(100, total / sleepGoal * 100)))% del objetivo de \(Int(sleepGoal)) h").font(.subheadline).foregroundStyle(Color.pulseMuted) } else { Text("Sin datos de sueño accesibles para el período reciente.").font(.subheadline).foregroundStyle(Color.pulseMuted) } }.padding(22).frame(maxWidth: .infinity, alignment: .leading).background(Color.pulseCard, in: RoundedRectangle(cornerRadius: 22))
                    SectionHeader(title: "Tu horario")
                    HStack { sleepTime(title: "Inicio", date: health.sleep.start, icon: "moon.fill"); Spacer(); sleepTime(title: "Fin", date: health.sleep.end, icon: "sun.max.fill") }.padding(18).background(Color.pulseCard, in: RoundedRectangle(cornerRadius: 18))
                    SectionHeader(title: "Últimos 7 días")
                    Text("El historial diario detallado se habilitará cuando esté implementada la agregación por noche. Por ahora se muestra el resumen más reciente disponible sin inventar días faltantes.").font(.subheadline).foregroundStyle(Color.pulseMuted).padding(18).frame(maxWidth: .infinity, alignment: .leading).background(Color.pulseCard, in: RoundedRectangle(cornerRadius: 18))
                    SectionHeader(title: "Fases del sueño")
                    Text("Solo se mostrarán cuando una fuente en Apple Salud registre fases compatibles. Esta versión no las estima.").font(.subheadline).foregroundStyle(Color.pulseMuted)
                    Text("El cumplimiento del objetivo indica duración relativa, no calidad clínica del sueño.").font(.caption).foregroundStyle(Color.pulseMuted)
                }.padding(20)
            }.background(Color.pulseBackground).navigationTitle("Sleep")
        }
    }
    @ViewBuilder private func sleepTime(title: String, date: Date?, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) { Image(systemName: icon).foregroundStyle(.pulseBlue); Text(title).font(.caption).foregroundStyle(Color.pulseMuted); Text(date?.pulseTime ?? "—").font(.title3.bold()) }
    }
}
