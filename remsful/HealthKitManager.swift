import SwiftUI
import HealthKit

@MainActor
public class HealthKitManager: ObservableObject, Sendable {
    public let healthStore = HKHealthStore()
    @Published var heartRate: Double = 60.0
    @Published var respiratoryRate: Double = 15.0
    
    public init(heartRate: Double = 60.0, respiratoryRate: Double = 15.0) {
        self.heartRate = heartRate
        self.respiratoryRate = respiratoryRate
    }
    
    public func requestAuthorization() async {
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let respiratoryRateType = HKQuantityType.quantityType(forIdentifier: .respiratoryRate)!
        
        do {
            try await healthStore.requestAuthorization(toShare: [], read: [heartRateType, respiratoryRateType])
            await fetchLatestHeartRate()
            await fetchLatestRespiratoryRate()
        } catch {
            print("Failed to request authorization: \(error)")
        }
    }
    
    public func fetchLatestHeartRate() async {
        if let rate = await fetchLatestData(for: .heartRate) {
            self.heartRate = rate
        }
    }
    
    public func fetchLatestRespiratoryRate() async {
        if let rate = await fetchLatestData(for: .respiratoryRate) {
            self.respiratoryRate = rate
        }
    }
    
    private func fetchLatestData(for identifier: HKQuantityTypeIdentifier) async -> Double? {
        let quantityType = HKQuantityType.quantityType(forIdentifier: identifier)!
        let predicate = HKQuery.predicateForSamples(withStart: Date().addingTimeInterval(-3600), end: nil, options: .strictStartDate)
        
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: quantityType,
                                          quantitySamplePredicate: predicate,
                                          options: .mostRecent) { _, result, error in
                guard let result = result, let quantity = result.mostRecentQuantity() else {
                    continuation.resume(returning: nil)
                    return
                }
                let value = quantity.doubleValue(for: HKUnit(from: "count/min"))
                continuation.resume(returning: value)
            }
            healthStore.execute(query)
        }
    }
}
