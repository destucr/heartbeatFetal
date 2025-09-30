//
//  HomeView.swift
//  heartbeatFetal
//
//  Created by Destu Cikal Ramdani on 30/09/25.
//

import SwiftUI
import AVFoundation

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()

    var body: some View {
        VStack(spacing: 20) {
            Text("Live Listen")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 50)

            Text("Use your iPhone as a microphone and listen through your AirPods.")
                .font(.headline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer()

            // Live Listen Toggle
            VStack {
                Toggle(isOn: $viewModel.isLiveListenOn) {
                    HStack {
                        Image(systemName: "ear")
                        Text("Live Listen")
                            .font(.headline)
                    }
                }
                .onChange(of: viewModel.isLiveListenOn) { oldValue, newValue in
                    viewModel.toggleLiveListen(enabled: newValue)
                }

                if viewModel.isLiveListenOn {
                    if let deviceName = viewModel.currentOutputDeviceName {
                        Text("Streaming to \(deviceName)")
                            .font(.caption)
                            .foregroundColor(.green)
                    } else {
                        Text("Live Listen is active - audio is streaming to your hearing device")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)

            Spacer()
        }
        .onAppear {
            viewModel.requestMicrophonePermission()
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage)
        }
    }
}
