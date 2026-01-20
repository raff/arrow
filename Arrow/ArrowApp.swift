//
//  ArrowApp.swift
//  Arrow
//
//  Created by Raffaele Sena on 1/8/26.
//

import SwiftUI

@main
struct ArrowApp: App {
    @State private var showSplash = true
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                
                // Splash screen overlay at app level
                if showSplash {
                    SplashScreenView()
                        .transition(.opacity)
                        .zIndex(2)
                }
            }
            .onAppear {
                // Hide splash screen after 1 second
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        showSplash = false
                    }
                }
            }
        }
    }
}
