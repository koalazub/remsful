//
//  HealthKitManager.swift
//  remsful
//
//  Created by Ali El Ali on 8/12/2024.
//
import SwiftUI
import HealthKit

public class HealthKitManager: ObservableObject {
    public let healthStore = HKHealthStore()
    @Published var respiratoryRate: Double = 15.0 // Default value
    
    public init(respiratoryRate: Double) { }
    
    public func requestAuthorization() {
        let respiratoryType = HKQuantityType.quantityType(forIdentifier: .respiratoryRate)!
        
        healthStore.requestAuthorization(toShare: [], read: [respiratoryType]) { success, error in
            if success {
                self.fetchLatestRespiratoryRate()
            }
        }
    }
    
    public func fetchLatestRespiratoryRate() {
        let respiratoryType = HKQuantityType.quantityType(forIdentifier: .respiratoryRate)!
        let query = HKStatisticsQuery(quantityType: respiratoryType,
                                      quantitySamplePredicate: nil,
                                      options: .mostRecent) { _, result, _ in
            guard let result = result, let average = result.averageQuantity() else { return }
            let rate = average.doubleValue(for: HKUnit(from: "count/min"))
            DispatchQueue.main.async {
                self.respiratoryRate = rate
            }
        }
        healthStore.execute(query)
    }
}
