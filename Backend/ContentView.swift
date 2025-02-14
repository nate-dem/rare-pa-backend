//
//  ContentView.swift
//  Backend
//
//  Created by nate demchak on 2/6/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var workoutManager = WorkoutSessionManager()
    
    var body: some View {
        VStack(spacing: 20) {
            // Connection Status
            HStack {
                Image(systemName: workoutManager.isWatchConnected ? "applewatch.radiowaves.left.and.right" : "applewatch.slash")
                    .foregroundColor(workoutManager.isWatchConnected ? .green : .red)
                Text(workoutManager.connectionStatus)
                    .font(.subheadline)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            
            if workoutManager.isWatchConnected {
                if workoutManager.isSessionActive {
                    HeartRateView(heartRate: workoutManager.currentHeartRate)
                    
                    if !workoutManager.currentSessionID.isEmpty {
                        Text("Session ID: \(workoutManager.currentSessionID)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text("Waiting for workout to start on Watch...")
                        .font(.headline)
                }
            } else {
                VStack(spacing: 15) {
                    Image(systemName: "applewatch.watchface")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    
                    Button(action: {
                        workoutManager.checkWatchConnection()
                    }) {
                        Text("Check Watch Connection")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                }
            }
        }
        .padding()
        .onAppear {
            workoutManager.checkWatchConnection()
        }
    }
}
