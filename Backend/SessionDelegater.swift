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
    
    // watch session
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.workoutManager?.checkWatchConnection()
        }
    }
    
    // check if watch connectivity failed
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
    
    // watch connectivity changed
    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.workoutManager?.checkWatchConnection()
        }
    }
    
    // session updates
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
