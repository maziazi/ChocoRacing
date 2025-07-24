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

            VStack(spacing: 10) {
                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 450, height: 400)
                    .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 3)

                ProgressView("Loading Assets...")
                    .progressViewStyle(CircularProgressViewStyle(tint: .black))
                    .foregroundColor(.black)
                    .font(.headline)
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
