import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var health: HealthStore
    @AppStorage("pulse21.sleepGoal") private var sleepGoal = 8.0
    var body: some View {
        NavigationStack {
            Form {
                Section("Apple Salud") {
                    HStack { Label("HealthKit", systemImage: "heart.text.square.fill"); Spacer(); Text(health.lastUpdated == nil ? "Sin sincronizar" : "Actualizado").font(.caption).foregroundStyle(health.lastUpdated == nil ? .orange : .pulseMint) }
                    Button { Task { await health.requestAccessAndSync() } } label: { HStack { Text("Conectar con Apple Salud"); Spacer(); if health.isLoading { ProgressView() } else { Image(systemName: "arrow.up.right.square") } } }.disabled(health.isLoading || !health.isAvailable)
                    Button("Actualizar datos ahora") { Task { await health.refresh() } }.disabled(health.isLoading)
                    Text("PULSE 21 lee los datos de Apple Salud. Flujo previsto: QWatch Pro → Apple Salud → PULSE 21; no hay conexión directa con la pulsera.").font(.caption).foregroundStyle(.secondary)
                    Text("Para revisar permisos: iPhone → Salud → foto de perfil → Apps y servicios → PULSE 21. Los permisos de lectura denegados pueden ser indistinguibles de la ausencia de datos.").font(.caption).foregroundStyle(.secondary)
                    if let error = health.errorMessage { Text(error).foregroundStyle(.orange).font(.caption) }
                }
                Section("Objetivo de sueño") { VStack(alignment: .leading) { Text("\(sleepGoal, specifier: "%.1f") horas por noche"); Slider(value: $sleepGoal, in: 5...12, step: 0.5).tint(.pulseBlue) } }
                Section("Cómo se calculan las métricas") {
                    Text("Strain: estimación propia a partir de duración e intensidad percibida de entrenamientos y, cuando se integre el muestreo continuo, carga cardíaca. No reproduce el algoritmo de WHOOP.")
                    Text("Recovery: compara HRV y frecuencia en reposo con una línea de base personal, además del sueño y la carga reciente. Esta versión no construye todavía una línea de base histórica automática, por lo que la puntuación permanece en calibración cuando faltan comparaciones.")
                    Text("Sleep: suma intervalos de sueño y fusiona solapamientos para no duplicar horas. La regularidad y la vista de siete días están pendientes.")
                }
                Section("Privacidad y estado") { Label("Procesamiento local", systemImage: "lock.fill"); Text("No se usa backend ni se envían datos a servidores. Los registros manuales se guardan localmente en el dispositivo."); Text("Última actualización: \(health.lastUpdated?.formatted(date: .abbreviated, time: .shortened) ?? "Nunca")").font(.caption).foregroundStyle(.secondary) }
                Section("PULSE 21") { Text("Versión de desarrollo · No es un producto oficial de WHOOP ni una herramienta médica.").font(.caption).foregroundStyle(.secondary) }
            }.scrollContentBackground(.hidden).background(Color.pulseBackground).navigationTitle("Settings")
        }.tint(.pulseLime)
    }
}
