//
//  ChangeCharacterView.swift
//  ChocoRacing
//
//  Created by Jennifer Evelyn on 23/07/25.
//

import SwiftUI
import AVFoundation

struct ChangeCharacterView: View {
    let characters = [
        ("octodonut", "player_octodonut"),
        ("sheepberry", "player_sheepberry"),
        ("bunsmores", "player_bunsmores"),
        ("whaleffle", "player_whaleffle")
    ]

    @State private var currentIndex = 0
    @Environment(\.dismiss) var dismiss
    @StateObject private var menuAudio = MenuAudioManager.shared
    
    @State private var clickPlayer: AVAudioPlayer?

    var body: some View {
        ZStack {
            Image("background")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Button(action: {
                        playClickSound()
                        dismiss()
                    }) {
                        Image("button_back")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 45, height: 45)
                            .padding(.leading, 20)
                            .padding(.top, 30)
                    }
                    Spacer()
                }

                Spacer().frame(height: 180)

                ZStack {
                    HStack(alignment: .center, spacing: 0) {
                        Button(action: {
                            playClickSound()
                            currentIndex = (currentIndex - 1 + characters.count) % characters.count
                        }) {
                            Image("button_leftArrow")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 30, height: 30)
                        }

                        ZStack {
                            Image("box_changeCharacter")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 300)

                            VStack(spacing: 20) {
                                Spacer().frame(height: 80)

                                Image("text_\(characters[currentIndex].0.lowercased())")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 40)

                                Button(action: {
                                    let selected = characters[currentIndex].0
                                    UserDefaults.standard.set(selected, forKey: "selectedCharacter")
                                    dismiss()
                                }) {
                                    Image("button_choose")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 180, height: 60)
                                }
                            }
                            .padding(.vertical, 25)
                            .padding(.horizontal, 10)
                            .frame(maxWidth: 260)
                        }

                        Button(action: {
                            playClickSound()
                            currentIndex = (currentIndex + 1) % characters.count
                        }) {
                            Image("button_rightArrow")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 30, height: 30)
                        }
                    }

                    Image(characters[currentIndex].1)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 260, height: 260)
                        .offset(y: -140)
                        .zIndex(1)
                }

                Spacer()
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            if let savedName = UserDefaults.standard.string(forKey: "selectedCharacter"),
               let index = characters.firstIndex(where: { $0.0 == savedName }) {
                currentIndex = index
            }
            menuAudio.playMenuMusic()
        }
    }

    func playClickSound() {
        if let url = Bundle.main.url(forResource: "click", withExtension: "wav") {
            do {
                clickPlayer = try AVAudioPlayer(contentsOf: url)
                clickPlayer?.prepareToPlay()
                clickPlayer?.play()
            } catch {
                print("❌ Gagal memutar click: \(error.localizedDescription)")
            }
        } else {
            print("❌ File click.mp3 tidak ditemukan")
        }
    }
}
