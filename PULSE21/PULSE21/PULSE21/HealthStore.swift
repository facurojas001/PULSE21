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

        [
            HKQuantityTypeIdentifier.heartRate,
            .restingHeartRate,
            .heartRateVariabilitySDNN,
            .stepCount,
            .activeEnergyBurned,
            .distanceWalkingRunning
        ].forEach { identifier in
            if let type = HKObjectType.quantityType(forIdentifier: identifier) {
                types.insert(type)
            }
        }

        if let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
            types.insert(sleepType)
        }

        types.insert(HKObjectType.workoutType())
        return types
    }

    func requestAccessAndSync() async {
        guard isAvailable else {
            errorMessage = PulseError.unavailable.localizedDescription
            return
        }

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
        guard isAvailable else {
            errorMessage = PulseError.unavailable.localizedDescription
            return
        }

        isLoading = true
        errorMessage = nil

        let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())

        // Consultas secuenciales: evita mutaciones concurrentes de propiedades @MainActor.
        heartRate = await loadLatestQuantity(.heartRate, unit: heartRateUnit)
        restingHeartRate = await loadLatestQuantity(.restingHeartRate, unit: heartRateUnit)
        hrv = await loadLatestQuantity(
            .heartRateVariabilitySDNN,
            unit: .secondUnit(with: .milli)
        )

        steps = await loadTodaySum(.stepCount, unit: .count())
        activeEnergy = await loadTodaySum(.activeEnergyBurned, unit: .kilocalorie())
        walkingRunningDistance = await loadTodaySum(.distanceWalkingRunning, unit: .meter())

        await loadSleep()
        await loadWorkouts()

        lastUpdated = Date()
        isLoading = false
    }

    private func loadLatestQuantity(
        _ identifier: HKQuantityTypeIdentifier,
        unit: HKUnit
    ) async -> Double? {
        guard let type = HKObjectType.quantityType(forIdentifier: identifier) else {
            return nil
        }

        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        do {
            let value: Double? = try await withCheckedThrowingContinuation { continuation in
                let query = HKSampleQuery(
                    sampleType: type,
                    predicate: nil,
                    limit: 1,
                    sortDescriptors: [sort]
                ) { _, samples, error in
                    if let error {
                        continuation.resume(throwing: error)
                        return
                    }

                    let sample = samples?.first as? HKQuantitySample
                    continuation.resume(returning: sample?.quantity.doubleValue(for: unit))
                }

                store.execute(query)
            }

            return value
        } catch {
            return nil
        }
    }

    private func loadTodaySum(
        _ identifier: HKQuantityTypeIdentifier,
        unit: HKUnit
    ) async -> Double? {
        guard let type = HKObjectType.quantityType(forIdentifier: identifier) else {
            return nil
        }

        let now = Date()
        let start = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(
            withStart: start,
            end: now,
            options: .strictStartDate
        )

        do {
            let value: Double? = try await withCheckedThrowingContinuation { continuation in
                let query = HKStatisticsQuery(
                    quantityType: type,
                    quantitySamplePredicate: predicate,
                    options: .cumulativeSum
                ) { _, result, error in
                    if let error {
                        continuation.resume(throwing: error)
                        return
                    }

                    continuation.resume(
                        returning: result?.sumQuantity()?.doubleValue(for: unit)
                    )
                }

                store.execute(query)
            }

            return value
        } catch {
            return nil
        }
    }

    private func loadSleep() async {
        guard let type = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            sleep = SleepSummary(totalHours: nil, start: nil, end: nil)
            return
        }

        let calendar = Calendar.current
        let now = Date()
        let today = calendar.startOfDay(for: now)
        let start = calendar.date(byAdding: .day, value: -1, to: today) ?? today
        let predicate = HKQuery.predicateForSamples(
            withStart: start,
            end: now,
            options: []
        )

        do {
            let samples: [HKCategorySample] = try await withCheckedThrowingContinuation { continuation in
                let query = HKSampleQuery(
                    sampleType: type,
                    predicate: predicate,
                    limit: HKObjectQueryNoLimit,
                    sortDescriptors: [
                        NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
                    ]
                ) { _, results, error in
                    if let error {
                        continuation.resume(throwing: error)
                        return
                    }

                    continuation.resume(returning: results as? [HKCategorySample] ?? [])
                }

                store.execute(query)
            }

            // Unimos intervalos solapados para evitar duplicar minutos de sueño.
            let asleep = samples.filter { sample in
                if #available(iOS 16.0, *) {
                    return sample.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue
                        || sample.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue
                        || sample.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue
                        || sample.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue
                } else {
                    return sample.value == HKCategoryValueSleepAnalysis.asleep.rawValue
                }
            }

            let intervals = asleep
                .map { ($0.startDate, $0.endDate) }
                .sorted { $0.0 < $1.0 }

            var merged: [(Date, Date)] = []

            for interval in intervals {
                if let last = merged.last, interval.0 <= last.1 {
                    merged[merged.count - 1].1 = max(last.1, interval.1)
                } else {
                    merged.append(interval)
                }
            }

            let totalHours = merged.reduce(0.0) {
                $0 + max(0, $1.1.timeIntervalSince($1.0))
            } / 3600.0

            sleep = SleepSummary(
                totalHours: merged.isEmpty ? nil : totalHours,
                start: merged.first?.0,
                end: merged.last?.1
            )
        } catch {
            sleep = SleepSummary(totalHours: nil, start: nil, end: nil)
        }
    }

    private func loadWorkouts() async {
        let now = Date()
        let start = Calendar.current.date(byAdding: .day, value: -30, to: now) ?? .distantPast
        let predicate = HKQuery.predicateForSamples(
            withStart: start,
            end: now,
            options: []
        )

        do {
            let samples: [HKWorkout] = try await withCheckedThrowingContinuation { continuation in
                let query = HKSampleQuery(
                    sampleType: .workoutType(),
                    predicate: predicate,
                    limit: HKObjectQueryNoLimit,
                    sortDescriptors: [
                        NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
                    ]
                ) { _, results, error in
                    if let error {
                        continuation.resume(throwing: error)
                        return
                    }

                    continuation.resume(returning: results as? [HKWorkout] ?? [])
                }

                store.execute(query)
            }

            workouts = samples.map { workout in
                WorkoutRecord(
                    title: workout.workoutActivityType.displayName,
                    start: workout.startDate,
                    durationMinutes: workout.duration / 60,
                    rpe: nil,
                    source: workout.sourceRevision.source.name,
                    energyKcal: workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()),
                    isManual: false
                )
            }
        } catch {
            workouts = []
        }
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
