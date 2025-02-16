//
//  WorkoutSessionManager.swift
//  Watch Backend
//
//  Created by nate demchak on 2/6/25.
//

import Foundation
import WatchConnectivity
import FirebaseDatabase

@MainActor
class WorkoutSessionManager: NSObject, ObservableObject {
    @Published var isWatchConnected = false
    @Published var currentHeartRate: Double = 0.0
    @Published var isSessionActive = false
    @Published var currentSessionID: String = ""
    @Published var connectionStatus = "Checking Watch connection..."
    
    private let databaseRef: DatabaseReference
    private let session: WCSession
    private let sessionDelegater: SessionDelegater
    
    override init() {
        print("Initializing iOS WorkoutSessionManager...")
        
        // init Firebase
        let databaseURL = "https://rare-pa-backend-default-rtdb.firebaseio.com/"
        self.databaseRef = Database.database(url: databaseURL).reference()
        
        // init WatchConnectivity
        self.session = WCSession.default
        self.sessionDelegater = SessionDelegater()
        
        super.init()
        
        self.sessionDelegater.setWorkoutManager(self)
        
        // set up WatchConnectivity
        if WCSession.isSupported() {
            session.delegate = sessionDelegater
            session.activate()
            checkWatchConnection()
        } else {
            connectionStatus = "Watch connectivity not supported on this device"
        }
    }
    
    // check WatchConnectivity
    func checkWatchConnection() {
        guard WCSession.isSupported() else {
            updateConnectionStatus("Watch connectivity not supported")
            return
        }
        
        switch session.activationState {
        case .activated:
            if session.isPaired {
                if session.isWatchAppInstalled {
                    if session.isReachable {
                        updateConnectionStatus("Watch connected and reachable")
                        isWatchConnected = true
                        
                    } else {
                        updateConnectionStatus("Watch app not reachable. Please open the Watch app")
                    }
                } else {
                    updateConnectionStatus("Watch app not installed")
                }
            } else {
                updateConnectionStatus("No Apple Watch paired")
            }
        case .inactive:
            updateConnectionStatus("Watch connectivity inactive")
        case .notActivated:
            updateConnectionStatus("Watch connectivity not activated")
        @unknown default:
            updateConnectionStatus("Unknown watch connection state")
        }
    }
    
    // watch connection status changed
    private func updateConnectionStatus(_ status: String) {
        DispatchQueue.main.async {
            self.connectionStatus = status
            print("Watch Status: \(status)")
        }
    }

    // main function for sending health data to Firebase
    func sendHeartRateToFirebase(heartRate: Double, timestamp: Int) {
        let heartRateData: [String: Any] = [
            "heartRate": heartRate,
            "timestamp": timestamp
        ]
        
        currentHeartRate = heartRate
        isSessionActive = true
        
        // Generate a session ID if one doesn't exist
        if currentSessionID.isEmpty {
            currentSessionID = UUID().uuidString
        }
        
        databaseRef.child("sessions").child(currentSessionID).child("heartRate").childByAutoId().setValue(heartRateData) { error, _ in
            if let error = error {
                print("Error sending heart rate to Firebase: \(error.localizedDescription)")
            } else {
                print("Heart rate sent to Firebase successfully")
            }
        }
    }
}
