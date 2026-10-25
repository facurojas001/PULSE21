import Foundation

/// Transparent, heuristic daily load score. It is not WHOOP's proprietary algorithm.
enum StrainEngine {
    static func score(workouts: [WorkoutRecord], heartRateSamples: [Double] = [], rpeOverride: Int? = nil) -> StrainResult {
        let today = Calendar.current.startOfDay(for: Date())
        let todays = workouts.filter { Calendar.current.isDate($0.start, inSameDayAs: today) }
        guard !todays.isEmpty || !heartRateSamples.isEmpty || rpeOverride != nil else {
            return StrainResult(score: nil, explanation: "Faltan entrenamientos, datos de frecuencia cardíaca o RPE para estimar el esfuerzo.", dataCoverage: "Insuficiente")
        }
        // Activity load uses duration × perceived intensity; HR data contributes only when samples are supplied.
        let activityLoad = todays.reduce(0.0) { total, workout in
            let intensity = Double(workout.rpe ?? rpeOverride ?? 5) / 10.0
            return total + workout.durationMinutes * max(0.1, min(1, intensity))
        }
        let hrLoad = heartRateSamples.reduce(0.0) { $0 + max(0, min(1, ($1 - 60) / 140)) }
        let raw = activityLoad / 18 + hrLoad / 30 + Double(rpeOverride ?? 0) / 10
        let normalized = max(1, min(21, 1 + 20 * (1 - exp(-raw / 5))))
        return StrainResult(score: normalized, explanation: "Estimación propia basada en duración, intensidad percibida y muestras cardíacas disponibles. No es una medición clínica.", dataCoverage: heartRateSamples.isEmpty ? "Parcial: actividad/RPE" : "Parcial: actividad + FC")
    }
}

enum RecoveryEngine {
    static func score(hrv: Double?, baselineHRV: Double?, restingHR: Double?, baselineRestingHR: Double?, sleepHours: Double?, sleepGoal: Double, recentLoad: Double?, calibrationDays: Int) -> RecoveryResult {
        guard calibrationDays >= 7, hrv != nil || restingHR != nil, sleepHours != nil else {
            return RecoveryResult(score: nil, explanation: "Calibrando: se necesitan al menos 7 días de historial y datos de sueño más una métrica cardíaca.", calibrationDays: calibrationDays)
        }
        var weighted = 0.0, weights = 0.0
        if let hrv, let baselineHRV, baselineHRV > 0 {
            weighted += max(0, min(100, 50 + (hrv / baselineHRV - 1) * 100)) * 0.4; weights += 0.4
        }
        if let restingHR, let baselineRestingHR, baselineRestingHR > 0 {
            weighted += max(0, min(100, 50 - (restingHR / baselineRestingHR - 1) * 100)) * 0.25; weights += 0.25
        }
        if let sleepHours {
            weighted += max(0, min(100, sleepHours / max(1, sleepGoal) * 100)) * 0.25; weights += 0.25
        }
        if let recentLoad { weighted += max(0, min(100, 100 - recentLoad)) * 0.1; weights += 0.1 }
        guard weights > 0 else { return RecoveryResult(score: nil, explanation: "No hay suficientes métricas comparables con tu línea de base.", calibrationDays: calibrationDays) }
        return RecoveryResult(score: Int((weighted / weights).rounded()), explanation: "Estimación orientativa con las métricas disponibles; no diagnostica ni mide directamente la recuperación fisiológica.", calibrationDays: calibrationDays)
    }
}
