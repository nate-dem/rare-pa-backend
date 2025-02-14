//
//  ErrorView.swift
//  Watch Backend
//
//  Created by nate demchak on 2/3/25.
//


import SwiftUI

struct ErrorView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .resizable()
                .frame(width: 40, height: 36)
                .foregroundColor(.orange)
            
            Text("Error")
                .font(.headline)
                .fontWeight(.bold)
            
            Text(message)
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}