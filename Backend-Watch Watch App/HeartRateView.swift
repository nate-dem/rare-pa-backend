//
//  HeartRateView.swift
//  Watch Backend
//
//  Created by nate demchak on 2/3/25.
//


import SwiftUI

struct HeartRateView: View {
    let heartRate: Double
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "heart.fill")
                .resizable()
                .frame(width: 30, height: 24)
                .foregroundColor(.red)
                .symbolEffect(.bounce, options: .repeating)
            
            Text("\(Int(heartRate))")
                .font(.system(size: 36, weight: .bold, design: .rounded))
            
            Text("BPM")
                .font(.headline)
                .foregroundColor(.secondary)
        }
    }
}
