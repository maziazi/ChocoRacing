//
//  LoadingView.swift
//  ChocoRacing
//
//  Created by Jennifer Evelyn on 23/07/25.
//

import SwiftUI
import RealityKit
import PlayTest

struct SplashView: View {
    var onLoadingComplete: () -> Void
    
    @State private var isLoading = true
    
    var body: some View {
        ZStack {
            Image("background")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 290, height: 240)
                    .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 3)
                    .padding(.bottom, 270)
                
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .black))
                    .scaleEffect(1.3)
                    .padding(.bottom, -100)
                
                Image("text_loading")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 160)
                    .padding(.top, -10)
            }
        }
        .task {
            await preloadAssets()
            onLoadingComplete()
        }
    }
    
    func preloadAssets() async {
        let assetNames = [
            "CloudChunk", "Floor", "Mangkok", "PillBottle", "PLETES_Plan B_1",
            "Scene", "Skull", "SkyDome", "Slide", "SlideNCream",
            "smores", "ToyCar", "world_slide_v1"
        ]
        
        for name in assetNames {
            do {
                _ = try await Entity.load(named: name, in: playTestBundle)
                print("✅ Loaded: \(name)")
            } catch {
                print("❌ Failed to load: \(name) — \(error.localizedDescription)")
            }
        }
    }
}
