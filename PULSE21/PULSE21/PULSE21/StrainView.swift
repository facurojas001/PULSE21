import SwiftUI

struct StrainView: View {
    @EnvironmentObject var health: HealthStore
    @EnvironmentObject var activities: ActivityStore
    @State private var showingForm = false
    private var records: [WorkoutRecord] { (health.workouts + activities.manualActivities).sorted { $0.start > $1.start } }
    private var result: StrainResult { StrainEngine.score(workouts: records) }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 8) { Text("STRAIN").font(.caption.bold()).tracking(2).foregroundStyle(.pulseLime); Text(result.score.map { String(Int($0.rounded())) } ?? "—").font(.system(size: 68, weight: .bold, design: .rounded)); Text("de 21 · esfuerzo diario").foregroundStyle(Color.pulseMuted); Text(result.explanation).font(.subheadline).foregroundStyle(Color.pulseMuted) }.frame(maxWidth: .infinity, alignment: .leading).padding(22).background(Color.pulseCard, in: RoundedRectangle(cornerRadius: 22))
                    Button { showingForm = true } label: { Label("Registrar actividad", systemImage: "plus").font(.headline).frame(maxWidth: .infinity).padding(16).background(Color.pulseLime, in: RoundedRectangle(cornerRadius: 16)).foregroundStyle(.black) }
                    SectionHeader(title: "Entrenamientos", trailing: "ÚLTIMOS 30 DÍAS")
                    if records.isEmpty { Text("No se encontraron entrenamientos en Apple Salud ni registros manuales.").font(.subheadline).foregroundStyle(Color.pulseMuted).padding(18).frame(maxWidth: .infinity, alignment: .leading).background(Color.pulseCard, in: RoundedRectangle(cornerRadius: 18)) }
                    ForEach(records) { record in
                        HStack(spacing: 13) { Image(systemName: record.isManual ? "pencil" : "figure.run").foregroundStyle(record.isManual ? .pulseLime : .pulseMint).frame(width: 42, height: 42).background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 13)); VStack(alignment: .leading, spacing: 4) { Text(record.title).font(.headline); Text("\(record.start.formatted(date: .abbreviated, time: .shortened)) · \(record.source)").font(.caption).foregroundStyle(Color.pulseMuted) }; Spacer(); Text("\(Int(record.durationMinutes))m").font(.subheadline.monospacedDigit()) }.padding(14).background(Color.pulseCard, in: RoundedRectangle(cornerRadius: 16))
                    }
                    Text("El esfuerzo es una estimación experimental. Si faltan datos de frecuencia cardíaca o RPE, la puntuación puede no estar disponible o ser parcial.").font(.caption).foregroundStyle(Color.pulseMuted)
                }.padding(20)
            }.background(Color.pulseBackground).navigationTitle("Strain / Workout").sheet(isPresented: $showingForm) { ManualActivityForm() }
        }
    }
}

struct ManualActivityForm: View {
    @EnvironmentObject var activities: ActivityStore
    @Environment(\.dismiss) private var dismiss
    @State private var sport = "Rugby"
    @State private var duration = 60.0
    @State private var rpe = 7.0
    @State private var start = Date()
    private let sports = ["Rugby", "Gimnasio", "Carrera", "Caminata", "Bicicleta", "Natación", "Otro"]
    var body: some View {
        NavigationStack {
            Form {
                Section("Actividad") { Picker("Deporte", selection: $sport) { ForEach(sports, id: \.self) { Text($0) } }; DatePicker("Fecha y hora", selection: $start, displayedComponents: [.date, .hourAndMinute]); VStack(alignment: .leading) { Text("Duración: \(Int(duration)) min"); Slider(value: $duration, in: 5...300, step: 5).tint(.pulseLime) }; VStack(alignment: .leading) { Text("Esfuerzo percibido (RPE): \(Int(rpe))/10"); Slider(value: $rpe, in: 1...10, step: 1).tint(.pulseLime) } }
                Section { Text("Usá el registro manual solo si la actividad no figura en Apple Salud. Se evita agregar dos registros manuales similares, pero no se puede detectar con certeza una coincidencia con un entrenamiento de otra fuente.").font(.caption).foregroundStyle(.secondary) }
            }.scrollContentBackground(.hidden).background(Color.pulseBackground).navigationTitle("Registrar actividad").toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } }; ToolbarItem(placement: .confirmationAction) { Button("Guardar") { activities.add(title: sport, start: start, duration: duration, rpe: Int(rpe)); dismiss() }.disabled(duration <= 0) } }
        }.tint(.pulseLime)
    }
}
