//
//  ContentView.swift
//  Backend-Watch Watch App
//
//  Created by nate demchak on 2/6/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var workoutManager = WorkoutSessionManager()
    
    var body: some View {
        VStack(spacing: 10) {
            HeartRateView(heartRate: workoutManager.currentHeartRate)
                .padding()
            
            Text("Heart Rate: \(Int(workoutManager.currentHeartRate)) BPM")
                .font(.headline)
            
            Button(action: {
                if workoutManager.isWorkoutActive {
                    workoutManager.endWorkout()
                } else {
                    workoutManager.startWorkout()
                }
            }) {
                Text(workoutManager.isWorkoutActive ? "End Workout" : "Start Workout")
                    .font(.headline)
                    .padding()
                    .background(Color.accentColor)
                    .cornerRadius(8)
                    .foregroundColor(.white)
            }
        }
        .padding()
    }
}
