//
//  VisionPro.swift
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
    }
}
