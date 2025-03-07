//
//  VisionProWorkout.swift
//  Backend
//
//  Created by nate demchak on 2/27/25.
//

import Foundation
import FirebaseDatabase
import SwiftUI

@MainActor
class VisionProWorkout: ObservableObject {
    @Published var currentHeartRate: Double = 0.0
    @Published var isSessionActive: Bool = false
    @Published var currentSessionID: String = ""
    
    private let databaseRef: DatabaseReference
    private var heartRateListener: DatabaseHandle?
    
    // function in frontend ContentView.swift file for AVP
    func getHeartRate() -> Double {
        return currentHeartRate
    }
    
    init() {
        let databaseURL = "https://rare-pa-backend-default-rtdb.firebaseio.com/"
        self.databaseRef = Database.database(url: databaseURL).reference()
        
        // Important: Call the setup function to activate listeners
        setUpHeartRateListener()
    }
    
    private func setUpHeartRateListener() {
        databaseRef.child("sessions").observe(.childAdded) { [weak self] snapshot in
            // makes sure we don't have memory leaks
            guard let self = self else { return }
            self.currentSessionID = snapshot.key
            self.isSessionActive = true
            
            if let curListener = self.heartRateListener {
                self.databaseRef.removeObserver(withHandle: curListener)
            }
            
            self.heartRateListener = self.databaseRef
                .child("sessions")
                .child(self.currentSessionID)
                .child("heartRate")
                .observe(.childAdded) { [weak self] heartRateSnapshot in
                    guard
                        let self = self,
                        let heartRateData = heartRateSnapshot.value as? [String: Any],
                        let heartRate = heartRateData["heartRate"] as? Double
                    else { return }
                    
                    DispatchQueue.main.async {
                        self.currentHeartRate = heartRate
                    }
                }
        }
    }
        
    deinit {
        if let listener = heartRateListener {
            databaseRef.removeObserver(withHandle: listener)
        }
        databaseRef.removeAllObservers()
    }
}
