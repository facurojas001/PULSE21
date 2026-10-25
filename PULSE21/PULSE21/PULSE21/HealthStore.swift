import Foundation
import Combine
import HealthKit

@MainActor
final class HealthStore: ObservableObject {
    @Published var isAvailable = HKHealthStore.isHealthDataAvailable()
    @Published var isLoading = false
    @Published var lastUpdated: Date?
    @Published var errorMessage: String?
    @Published var connectionRequested = false
    @Published var heartRate: Double?
    @Published var restingHeartRate: Double?
    @Published var hrv: Double?
    @Published var steps: Double?
    @Published var activeEnergy: Double?
    @Published var walkingRunningDistance: Double?
    @Published var workouts: [WorkoutRecord] = []
    @Published var sleep = SleepSummary(totalHours: nil, start: nil, end: nil)

    private let store = HKHealthStore()
    private var readTypes: Set<HKObjectType> {
        var types = Set<HKObjectType>()
        [HKQuantityTypeIdentifier.heartRate, .restingHeartRate, .heartRateVariabilitySDNN, .stepCount,
         .activeEnergyBurned, .distanceWalkingRunning].forEach { id in
            if let t = HKObjectType.quantityType(forIdentifier: id) { types.insert(t) }
        }
        if let t = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) { types.insert(t) }
        types.insert(HKObjectType.workoutType())
        return types
    }

    func requestAccessAndSync() async {
        guard isAvailable else { errorMessage = PulseError.unavailable.localizedDescription; return }
        connectionRequested = true
        isLoading = true
        errorMessage = nil
        do {
            try await store.requestAuthorization(toShare: [], read: readTypes)
            await refresh()
        } catch {
            errorMessage = "No se pudo completar la solicitud de permisos: \(error.localizedDescription)"
        }
        isLoading = false
    }

    func refresh() async {
        guard isAvailable else { errorMessage = PulseError.unavailable.localizedDescription; return }
        isLoading = true
        errorMessage = nil
        async let hr: Void = loadLatestQuantity(.heartRate, unit: HKUnit.count().unitDivided(by: .minute)) { self.heartRate = $0 }
        async let rhr: Void = loadLatestQuantity(.restingHeartRate, unit: HKUnit.count().unitDivided(by: .minute)) { self.restingHeartRate = $0 }
        async let variability: Void = loadLatestQuantity(.heartRateVariabilitySDNN, unit: .secondUnit(with: .milli)) { self.hrv = $0 }
        async let stepCount: Void = loadTodaySum(.stepCount, unit: .count()) { self.steps = $0 }
        async let energy: Void = loadTodaySum(.activeEnergyBurned, unit: .kilocalorie()) { self.activeEnergy = $0 }
        async let distance: Void = loadTodaySum(.distanceWalkingRunning, unit: .meter()) { self.walkingRunningDistance = $0 }
        async let sleepLoad: Void = loadSleep()
        async let workoutLoad: Void = loadWorkouts()
        _ = await (hr, rhr, variability, stepCount, energy, distance, sleepLoad, workoutLoad)
        lastUpdated = Date()
        isLoading = false
    }

    private func loadLatestQuantity(_ id: HKQuantityTypeIdentifier, unit: HKUnit, assign: @escaping (Double?) -> Void) async {
        guard let type = HKObjectType.quantityType(forIdentifier: id) else { assign(nil); return }
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        do {
            let value: Double? = try await withCheckedThrowingContinuation { continuation in
                store.execute(HealthQueryShim.query(type: type, sort: sort) { samples, error in
                    if let error { continuation.resume(throwing: error); return }
                    let sample = samples?.first as? HKQuantitySample
                    continuation.resume(returning: sample?.quantity.doubleValue(for: unit))
                })
            }
            assign(value)
        } catch { assign(nil) }
    }

    private func loadTodaySum(_ id: HKQuantityTypeIdentifier, unit: HKUnit, assign: @escaping (Double?) -> Void) async {
        guard let type = HKObjectType.quantityType(forIdentifier: id) else { assign(nil); return }
        let start = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date(), options: .strictStartDate)
        do {
            let value: Double? = try await withCheckedThrowingContinuation { continuation in
                let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
                    if let error { continuation.resume(throwing: error); return }
                    continuation.resume(returning: result?.sumQuantity()?.doubleValue(for: unit))
                }
                store.execute(query)
            }
            assign(value)
        } catch { assign(nil) }
    }

    private func loadSleep() async {
        guard let type = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { sleep = SleepSummary(totalHours: nil, start: nil, end: nil); return }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let start = calendar.date(byAdding: .day, value: -1, to: today) ?? today
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date(), options: [])
        do {
            let samples: [HKCategorySample] = try await withCheckedThrowingContinuation { continuation in
                store.execute(HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]) { _, results, error in
                    if let error { continuation.resume(throwing: error); return }
                    continuation.resume(returning: results as? [HKCategorySample] ?? [])
                })
            }
            // Prefer asleep states; merge overlapping intervals to avoid double-counting source overlaps.
            let asleep = samples.filter { sample in
                if #available(iOS 16.0, *) {
                    return sample.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue || sample.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue || sample.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue || sample.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue
                }
                return sample.value == HKCategoryValueSleepAnalysis.asleep.rawValue
            }
            let intervals = asleep.map { ($0.startDate, $0.endDate) }.sorted { $0.0 < $1.0 }
            var merged: [(Date, Date)] = []
            for interval in intervals {
                if let last = merged.last, interval.0 <= last.1 {
                    merged[merged.count - 1].1 = max(last.1, interval.1)
                } else { merged.append(interval) }
            }
            let total = merged.reduce(0.0) { $0 + max(0, $1.1.timeIntervalSince($1.0)) } / 3600
            sleep = SleepSummary(totalHours: merged.isEmpty ? nil : total, start: merged.first?.0, end: merged.last?.1)
        } catch { sleep = SleepSummary(totalHours: nil, start: nil, end: nil) }
    }

    private func loadWorkouts() async {
        let start = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? .distantPast
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date(), options: [])
        do {
            let samples: [HKWorkout] = try await withCheckedThrowingContinuation { continuation in
                store.execute(HKSampleQuery(sampleType: .workoutType(), predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]) { _, results, error in
                    if let error { continuation.resume(throwing: error); return }
                    continuation.resume(returning: results as? [HKWorkout] ?? [])
                })
            }
            workouts = samples.map { workout in
                WorkoutRecord(title: workout.workoutActivityType.displayName, start: workout.startDate,
                              durationMinutes: workout.duration / 60, rpe: nil, source: workout.sourceRevision.source.name,
                              energyKcal: workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()), isManual: false)
            }
        } catch { workouts = [] }
    }
}

private enum HealthQueryShim {
    static func query(type: HKQuantityType, sort: NSSortDescriptor, completion: @escaping ([HKSample]?, Error?) -> Void) -> HKSampleQuery {
        HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sort], resultsHandler: { _, samples, error in completion(samples, error) })
    }
}

private extension HKWorkoutActivityType {
    var displayName: String {
        switch self {
        case .running: return "Carrera"
        case .walking: return "Caminata"
        case .cycling: return "Bicicleta"
        case .traditionalStrengthTraining, .functionalStrengthTraining: return "Gimnasio"
        case .rugby: return "Rugby"
        case .swimming: return "Natación"
        default: return "Entrenamiento"
        }
    }
}
