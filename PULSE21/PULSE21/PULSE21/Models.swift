import Foundation
import HealthKit

enum PulseTab: String, CaseIterable, Identifiable {
    case today = "Today", strain = "Strain", sleep = "Sleep", settings = "Settings"
    var id: String { rawValue }
    var symbol: String { switch self { case .today: return "circle.grid.2x2.fill"; case .strain: return "figure.run"; case .sleep: return "moon.zzz.fill"; case .settings: return "slider.horizontal.3" } }
}

struct WorkoutRecord: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var start: Date
    var durationMinutes: Double
    var rpe: Int?
    var source: String
    var energyKcal: Double?
    var isManual: Bool
}

struct SleepSummary {
    var totalHours: Double?
    var start: Date?
    var end: Date?
    var stages: [String: Double] = [:]
    var dailyHours: [(Date, Double)] = []
}

struct StrainResult {
    let score: Double?
    let explanation: String
    let dataCoverage: String
}

struct RecoveryResult {
    let score: Int?
    let explanation: String
    let calibrationDays: Int
}

enum PulseError: LocalizedError {
    case unavailable
    var errorDescription: String? { "Apple Salud / HealthKit no está disponible en este dispositivo." }
}
