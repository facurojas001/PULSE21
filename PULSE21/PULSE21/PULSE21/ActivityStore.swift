import Foundation
import Combine

@MainActor
final class ActivityStore: ObservableObject {
    @Published private(set) var manualActivities: [WorkoutRecord] = []
    private let key = "pulse21.manualActivities.v1"
    init() { load() }
    func add(title: String, start: Date, duration: Double, rpe: Int) {
        guard duration > 0 else { return }
        // Avoid a likely duplicate manual entry of same sport and time window.
        let duplicate = manualActivities.contains { $0.title == title && abs($0.start.timeIntervalSince(start)) < 30 * 60 }
        guard !duplicate else { return }
        manualActivities.append(WorkoutRecord(title: title, start: start, durationMinutes: duration, rpe: rpe, source: "Registro manual", energyKcal: nil, isManual: true))
        save()
    }
    func remove(_ record: WorkoutRecord) { manualActivities.removeAll { $0.id == record.id }; save() }
    private func load() { if let data = UserDefaults.standard.data(forKey: key), let records = try? JSONDecoder().decode([WorkoutRecord].self, from: data) { manualActivities = records } }
    private func save() { if let data = try? JSONEncoder().encode(manualActivities) { UserDefaults.standard.set(data, forKey: key) } }
}
