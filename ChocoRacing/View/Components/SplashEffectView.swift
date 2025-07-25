//
//  SplashEffectView.swift
//  ChocoRacing
//
//  Created by ivan sunjaya on 25/07/25.
//


// SplashEffectView.swift

import SwiftUI

struct SplashEffectView: View {
    @Binding var splashVisible: Bool
    @State private var splashScale: CGFloat = 0.5
    
    var body: some View {
        if splashVisible {
            Image("powerDown_bomb") // Pastikan gambar powerDown_bomb sudah ditambahkan ke assets
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 200)
                .padding(.bottom, 100)
                .opacity(splashVisible ? 1.0 : 0.0) // Menambahkan animasi fade in/out pada opacity
                .onAppear {
                    // Terapkan animasi scale pada splash saat muncul
                    withAnimation(.easeIn(duration: 0.2)) {
                        splashScale = 1.5 // Efek scale pada splash
                    }
                }
                .scaleEffect(splashScale) // Terapkan efek scale yang diubah di atas
                .onDisappear {
                    // Menambahkan animasi transisi lebih smooth saat hilang
                    withAnimation(.easeOut(duration: 0.5)) {
                        splashScale = 0.5 // Kembali ke ukuran awal
                    }
                }
        }
    }
}

