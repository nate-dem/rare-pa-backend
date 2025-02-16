//
//  SessionDelegater.swift
//  Watch Backend
//
//  Created by nate demchak on 2/6/25.
//

import WatchConnectivity
import HealthKit

class SessionDelegater: NSObject, WCSessionDelegate {
    private weak var workoutManager: WorkoutSessionManager?
    
    func setWorkoutManager(_ manager: WorkoutSessionManager) {
        self.workoutManager = manager
    }
    
    // Required WCSessionDelegate methods
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.workoutManager?.checkWatchConnection()
        }
    }
    
    // Required for iOS
    func sessionDidBecomeInactive(_ session: WCSession) {
        DispatchQueue.main.async {
            self.workoutManager?.checkWatchConnection()
        }
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        DispatchQueue.main.async {
            self.workoutManager?.checkWatchConnection()
            session.activate()
        }
        
    }
    
    // Watch communication methods
    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.workoutManager?.checkWatchConnection()
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        guard let heartRate = message["heartRate"] as? Double,
              let timestamp = message["timestamp"] as? Int else {
            print("Received invalid heart rate message")
            return
        }
        
        DispatchQueue.main.async {
            self.workoutManager?.sendHeartRateToFirebase(heartRate: heartRate, timestamp: timestamp)
        }
    }
}
