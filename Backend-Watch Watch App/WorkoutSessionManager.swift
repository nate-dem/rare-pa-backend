//
//  WorkoutSessionManager.swift
//  Watch Backend
//
//  Created by nate demchak on 2/3/25.
//

import Foundation
import HealthKit
import WatchConnectivity
import SwiftUI

class WorkoutSessionManager: NSObject, ObservableObject {
    private let healthStore = HKHealthStore()
    private let session: WCSession
    private let sessionDelegater: SessionDelegater
    
    @Published var currentHeartRate: Double = 0.0
    @Published var isWorkoutActive = false
    
    private var workoutSession: HKWorkoutSession?
    private var workoutBuilder: HKLiveWorkoutBuilder?
    
    override init() {
        self.session = WCSession.default
        self.sessionDelegater = SessionDelegater()
        super.init()
        
        if WCSession.isSupported() {
            session.delegate = sessionDelegater
            session.activate()
        }
        
        requestAuthorization()
    }
    
    func requestAuthorization() {
        // guard let in case HKQuantityType fails
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            Swift.print("Unable to create heart rate type")
            return
        }
        
        let workoutType = HKObjectType.workoutType()
        
        let typesToShare: Set<HKSampleType> = [workoutType]
        let typesToRead: Set<HKObjectType> = [heartRateType, workoutType]
        
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { [weak self] success, error in
            guard let self = self else { return }
            if success {
                DispatchQueue.main.async {
                    self.startWorkout()
                }
            } else {
                Swift.print("HealthKit authorization failed")
            }
        }
    }
    
    @MainActor
    func startWorkout() {
        // set workout config to other and indoor for psychiatric assessment
        let config = HKWorkoutConfiguration()
        config.activityType = .other
        config.locationType = .indoor
        
        do {
            workoutSession = try HKWorkoutSession(healthStore: healthStore, configuration: config)
            workoutBuilder = workoutSession?.associatedWorkoutBuilder()
            
            // to receive updates
            workoutSession?.delegate = self
            workoutBuilder?.delegate = self
            
            workoutBuilder?.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: config)
            
            // set current time
            let date = Date()
            workoutSession?.startActivity(with: date)
            Task {
                do {
                    try await self.workoutBuilder?.beginCollection(at: date)
                } catch {
                    Swift.print("Error starting collection: \(error.localizedDescription)")
                }
            }
            
            self.isWorkoutActive = true
            
        } catch {
            Swift.print("Could not start workout session: \(error.localizedDescription)")
        }
    }
    
    @MainActor
    func endWorkout() {
        let endDate = Date()
        workoutSession?.end()
        Task {
            do {
                try await self.workoutBuilder?.endCollection(at: endDate)
            } catch {
                Swift.print("Error ending collection: \(error.localizedDescription)")
            }
            self.isWorkoutActive = false
        }
    }

    @MainActor
    private func sendHeartRateToPhone(_ heartRate: Double) {
        self.currentHeartRate = heartRate
        
        let message: [String: Any] = [
            "heartRate": heartRate,
            "timestamp": Int(Date().timeIntervalSince1970)
        ]
        
        if session.isReachable {
            session.sendMessage(message, replyHandler: nil) { error in
                print("Error sending heart rate to phone: \(error.localizedDescription)")
            }
        }
    }
}

extension WorkoutSessionManager: HKWorkoutSessionDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession,
                        didChangeTo toState: HKWorkoutSessionState,
                        from fromState: HKWorkoutSessionState,
                        date: Date) {
        print("Workout session changed from \(fromState) to \(toState) at \(date)")
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("Workout session failed with error: \(error.localizedDescription)")
    }
}

extension WorkoutSessionManager: HKLiveWorkoutBuilderDelegate {
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
    }
    
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder,
                        didCollectDataOf collectedTypes: Set<HKSampleType>) {

        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate),
              collectedTypes.contains(heartRateType) else { return }
        
        if let statistics = workoutBuilder.statistics(for: heartRateType),
           let quantity = statistics.mostRecentQuantity() {
            let heartRate = quantity.doubleValue(for: HKUnit(from: "count/min"))
            print("Updated heart rate: \(heartRate) BPM")
            Task {
                await self.sendHeartRateToPhone(heartRate)
            }
            
        }
    }
}
