//
//  SplashScreenView.swift
//  Arrow
//
//  Created on 1/19/26.
//

import SwiftUI

struct SplashScreenView: View {
    var body: some View {
        ZStack {
            // Solid background color
            Color(red: 0.2, green: 0.3, blue: 0.5)
                .ignoresSafeArea()
            
            // Background gradient overlay
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.blue.opacity(0.4),
                    Color.purple.opacity(0.3),
                    Color.green.opacity(0.2)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                // Static target icon
                ZStack {
                    // Outer rings
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 3)
                        .frame(width: 180, height: 180)
                    
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 3)
                        .frame(width: 140, height: 140)
                    
                    Circle()
                        .stroke(Color.white.opacity(0.4), lineWidth: 3)
                        .frame(width: 100, height: 100)
                    
                    // Center bullseye
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.yellow, Color.orange]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                        .shadow(color: Color.orange.opacity(0.5), radius: 10)
                    
                    // Arrow hitting center
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.white)
                        .rotationEffect(.degrees(-45))
                        .offset(x: 15, y: -15)
                        .shadow(color: Color.black.opacity(0.3), radius: 5)
                }
                
                // App title
                VStack(spacing: 8) {
                    Text("TARGET ARCHERY")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: Color.black.opacity(0.3), radius: 5)
                    
                    Text("Precision Simulator")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                        .tracking(2)
                }
                
                Spacer()
                Spacer()
            }
        }
    }
}

struct SplashScreenView_Previews: PreviewProvider {
    static var previews: some View {
        SplashScreenView()
    }
}
