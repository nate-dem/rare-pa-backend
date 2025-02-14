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

// MARK: - WorkoutSessionManager with Live Workout APIs

class WorkoutSessionManager: NSObject, ObservableObject {
    private let healthStore = HKHealthStore()
    private let session: WCSession
    private let sessionDelegater: SessionDelegater
    
    @Published var currentHeartRate: Double = 0.0
    @Published var isWorkoutActive = false
    
    // New properties for managing the workout session and builder
    private var workoutSession: HKWorkoutSession?
    private var workoutBuilder: HKLiveWorkoutBuilder?
    
    override init() {
        print("⌚️ Initializing WorkoutSessionManager...")
        self.session = WCSession.default
        self.sessionDelegater = SessionDelegater()
        super.init()
        
        if WCSession.isSupported() {
            session.delegate = sessionDelegater
            session.activate()
        }
        
        requestAuthorization()
    }
    
    // Request authorization for HealthKit types (heart rate and workouts)
    func requestAuthorization() {
        print("🔐 Requesting HealthKit authorization...")
        
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            print("❌ Unable to create heart rate type")
            return
        }
        
        let workoutType = HKObjectType.workoutType()
        let typesToShare: Set<HKSampleType> = [workoutType]
        let typesToRead: Set<HKObjectType> = [heartRateType, workoutType]
        
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { [weak self] success, error in
            guard let self = self else { return }
            if success {
                print("✅ HealthKit authorization granted")
                DispatchQueue.main.async {
                    self.startWorkout()
                }
            } else {
                print("❌ HealthKit authorization failed: \(error?.localizedDescription ?? "unknown error")")
            }
        }

    }
    
    // MARK: - Workout Session Management
    
    /// Call this method (for example, via a button tap) to start your custom workout session.
    func startWorkout() {
        print("🏃‍♂️ Starting workout session...")
        
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .other
        configuration.locationType = .unknown
        
        do {
            // Create the workout session and live workout builder
            workoutSession = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            workoutBuilder = workoutSession?.associatedWorkoutBuilder()
            
            // Set delegates so you receive updates
            workoutSession?.delegate = self
            workoutBuilder?.delegate = self
            
            // Set the data source to collect live data (including heart rate)
            workoutBuilder?.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: configuration)
            
            let startDate = Date()
            workoutSession?.startActivity(with: startDate)
            workoutBuilder?.beginCollection(withStart: startDate) { (success, error) in
                if !success {
                    print("❌ Error starting data collection: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
            
            DispatchQueue.main.async {
                self.isWorkoutActive = true
            }
            
            print("✅ Workout session started")
        } catch {
            print("❌ Failed to start workout session: \(error.localizedDescription)")
        }
    }
    
    /// Call this method to end your workout session.
    func endWorkout() {
        print("🏁 Ending workout session...")
        let endDate = Date()
        workoutSession?.end()
        workoutBuilder?.endCollection(withEnd: endDate, completion: { (success, error) in
            if !success {
                print("❌ Error ending data collection: \(error?.localizedDescription ?? "Unknown error")")
            }
            self.workoutBuilder?.finishWorkout { (workout, error) in
                if let error = error {
                    print("❌ Error finishing workout: \(error.localizedDescription)")
                } else {
                    print("✅ Workout finished: \(String(describing: workout))")
                }
            }
        })
        
        DispatchQueue.main.async {
            self.isWorkoutActive = false
        }
    }
    
    // MARK: - Sending Data to the iOS App
    
    private func sendHeartRateToPhone(_ heartRate: Double) {
        DispatchQueue.main.async {
            self.currentHeartRate = heartRate
        }
        
        let message: [String: Any] = [
            "heartRate": heartRate,
            "timestamp": Int(Date().timeIntervalSince1970)
        ]
        
        if session.isReachable {
            session.sendMessage(message, replyHandler: nil) { error in
                print("❌ Error sending heart rate to phone: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - HKWorkoutSessionDelegate

extension WorkoutSessionManager: HKWorkoutSessionDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession,
                        didChangeTo toState: HKWorkoutSessionState,
                        from fromState: HKWorkoutSessionState,
                        date: Date) {
        print("Workout session changed from \(fromState) to \(toState) at \(date)")
        // You might update your UI here based on state changes.
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("Workout session failed with error: \(error.localizedDescription)")
    }
}

// MARK: - HKLiveWorkoutBuilderDelegate

extension WorkoutSessionManager: HKLiveWorkoutBuilderDelegate {
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
        // Optional: Handle events if needed.
    }
    
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder,
                        didCollectDataOf collectedTypes: Set<HKSampleType>) {
        // Process heart rate data if available.
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate),
              collectedTypes.contains(heartRateType) else { return }
        
        if let statistics = workoutBuilder.statistics(for: heartRateType),
           let quantity = statistics.mostRecentQuantity() {
            let heartRate = quantity.doubleValue(for: HKUnit(from: "count/min"))
            print("💓 Updated heart rate: \(heartRate) BPM")
            sendHeartRateToPhone(heartRate)
        }
    }
}
