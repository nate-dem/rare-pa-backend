//
//  HeartRateView.swift
//  Watch Backend
//
//  Created by nate demchak on 2/6/25.
//

import SwiftUI

struct HeartRateView: View {
    let heartRate: Double
    
    var body: some View {
        VStack(spacing: 15) {
            Image(systemName: "heart.fill")
                .resizable()
                .frame(width: 50, height: 45)
                .foregroundColor(.red)
                .symbolEffect(.bounce, options: .repeating)
            
            Text("\(Int(heartRate))")
                .font(.system(size: 64, weight: .bold, design: .rounded))
            
            Text("BPM")
                .font(.headline)
                .foregroundColor(.secondary)
        }
    }
}
