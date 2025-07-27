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
    
    @State private var progress: Double = 0.0
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
                
                ZStack(alignment: .leading) {
                    // Fill bar grows from left
                    Image("progressBar_fill")
                        .resizable()
                        .frame(width: max(CGFloat(progress) * 300, 4), height: 24)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.vertical, 8)
                        .alignmentGuide(.leading) { _ in 0 }
                    
                    Image("progressBar_bg")
                        .resizable()
                        .frame(width: 300, height: 40)
                }
                .frame(width: 300, height: 40)
            }
        }
        .task {
            await preloadAssets()
        }
    }
    
    func preloadAssets() async {
        let assetNames = [
            "obstacle_chocoWall",
            "powerDown_slowDown_2",
            "powerDown_spray 2",
            "powerUp_protection 2",
            "powerUp_speedUp 2",
            "player_donutOcto",
            "player_donutOctopus",
            "player_raspberry",
            "player_smores",
            "player_waffle",
            "PLETES_Plan B_1",
            "world_shader_slide",
            "world_slide_v1",
            "world_startFinish",
            "enviroment_slide",
            "Scene",
            "ShieldBubble",
            "speedBoost"
        ]
        
        var loadedCount = 0
        
        for name in assetNames {
            do {
                _ = try await Entity.load(named: name, in: playTestBundle)
                print("✅ Loaded: \(name)")
            } catch {
                print("❌ Failed to load: \(name) — \(error.localizedDescription)")
            }

            loadedCount += 1
            let newProgress = Double(loadedCount) / Double(assetNames.count)
            
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.25)) {
                    progress = newProgress
                }
            }

            // delay agar progress terlihat smooth
            try? await Task.sleep(nanoseconds: 150_000_000)
        }

        await MainActor.run {
            withAnimation(.easeInOut(duration: 0.3)) {
                progress = 1.0
            }
        }

        try? await Task.sleep(nanoseconds: 500_000_000)

        await MainActor.run {
            onLoadingComplete()
        }
    }
}

#Preview {
    SplashView(onLoadingComplete: {})
}
