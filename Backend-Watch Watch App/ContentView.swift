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
            if workoutManager.isWorkoutActive {
                Text("Session Started!").font(.headline).padding(.bottom, 30)
            } else {
                Text("Session Ended!").font(.headline).padding(.bottom, 30)
            }
            
            Button(action: {
                if workoutManager.isWorkoutActive {
                    workoutManager.endWorkout()
                } else {
                    workoutManager.startWorkout()
                }
            }) {
                Text(workoutManager.isWorkoutActive ? "End Session" : "Start Session")
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
