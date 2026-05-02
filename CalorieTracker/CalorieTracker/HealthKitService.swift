import Foundation
import HealthKit

@MainActor
final class HealthKitService: ObservableObject {
    let store = HKHealthStore()

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    private var readTypes: Set<HKObjectType> {
        var types: Set<HKObjectType> = [HKObjectType.workoutType()]
        if let energy = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) {
            types.insert(energy)
        }
        return types
    }

    func requestAuthorization() async -> Bool {
        guard isAvailable else { return false }
        do {
            try await store.requestAuthorization(toShare: [], read: readTypes)
            return true
        } catch {
            return false
        }
    }

    func todayActiveEnergyKcal() async -> Int {
        guard isAvailable,
              let type = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) else {
            return 0
        }
        let start = Calendar.current.startOfDay(for: Date())
        let pred = HKQuery.predicateForSamples(withStart: start, end: Date(), options: .strictStartDate)

        return await withCheckedContinuation { cont in
            let q = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: pred,
                options: .cumulativeSum
            ) { _, stats, _ in
                let kcal = stats?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
                cont.resume(returning: Int(kcal.rounded()))
            }
            self.store.execute(q)
        }
    }

    func todayWorkouts() async -> [Activity] {
        guard isAvailable else { return [] }
        let start = Calendar.current.startOfDay(for: Date())
        let pred = HKQuery.predicateForSamples(withStart: start, end: Date(), options: .strictStartDate)
        let sort = NSSortDescriptor(keyPath: \HKSample.startDate, ascending: false)

        return await withCheckedContinuation { cont in
            let q = HKSampleQuery(
                sampleType: .workoutType(),
                predicate: pred,
                limit: 5,
                sortDescriptors: [sort]
            ) { _, samples, _ in
                let workouts = (samples as? [HKWorkout]) ?? []
                let acts = workouts.enumerated().map { i, w -> Activity in
                    let kcal: Int
                    if let stats = w.statistics(for: HKQuantityType(.activeEnergyBurned)),
                       let sum = stats.sumQuantity() {
                        kcal = Int(sum.doubleValue(for: .kilocalorie()).rounded())
                    } else {
                        kcal = 0
                    }
                    return Activity(
                        id: i,
                        type: workoutTypeName(w.workoutActivityType),
                        emoji: workoutEmoji(w.workoutActivityType),
                        kcal: kcal,
                        duration: formatDuration(w.duration)
                    )
                }
                cont.resume(returning: acts)
            }
            self.store.execute(q)
        }
    }
}

private func workoutEmoji(_ t: HKWorkoutActivityType) -> String {
    switch t {
    case .running:                                                  return "🏃"
    case .walking, .hiking:                                         return "🚶"
    case .cycling:                                                  return "🚴"
    case .traditionalStrengthTraining, .functionalStrengthTraining: return "🏋️"
    case .yoga, .pilates, .flexibility:                             return "🧘"
    case .swimming:                                                 return "🏊"
    case .dance, .cardioDance:                                      return "💃"
    case .rowing:                                                   return "🚣"
    case .elliptical:                                               return "⚙️"
    default:                                                        return "💪"
    }
}

private func workoutTypeName(_ t: HKWorkoutActivityType) -> String {
    switch t {
    case .running:                                                  return "Run"
    case .walking:                                                  return "Walk"
    case .hiking:                                                   return "Hike"
    case .cycling:                                                  return "Cycling"
    case .traditionalStrengthTraining, .functionalStrengthTraining: return "Strength"
    case .yoga:                                                     return "Yoga"
    case .pilates:                                                  return "Pilates"
    case .swimming:                                                 return "Swim"
    case .dance, .cardioDance:                                      return "Dance"
    case .rowing:                                                   return "Rowing"
    case .elliptical:                                               return "Elliptical"
    default:                                                        return "Workout"
    }
}

private func formatDuration(_ seconds: TimeInterval) -> String {
    let m = Int(seconds / 60)
    if m < 60 { return "\(m) min" }
    return "\(m / 60)h \(m % 60)m"
}
