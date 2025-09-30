//
//  HomeViewModel.swift
//  heartbeatFetal
//
//  Created by Destu Cikal Ramdani on 30/09/25.
//

import Foundation
import Combine
import AVFoundation
import Accessibility

class HomeViewModel: ObservableObject {
    @Published var isLiveListenOn = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var currentOutputDeviceName: String? = nil

    private var liveListenManager = LiveListenManager()
    private var cancellables = Set<AnyCancellable>()

    init() {
        print("[HomeViewModel] Initialized")
        liveListenManager.$currentOutputDeviceName
            .assign(to: \.currentOutputDeviceName, on: self)
            .store(in: &cancellables)
    }





    func requestMicrophonePermission() {
        print("[HomeViewModel] Requesting microphone permission")
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            print("[HomeViewModel] Microphone permission granted: \(granted)")
            if !granted {
                DispatchQueue.main.async {
                    self.errorMessage = "Microphone access is required for Live Listen"
                    self.showError = true
                    print("[HomeViewModel] Error: Microphone access denied")
                }
            }
        }
    }

    func toggleLiveListen(enabled: Bool) {
        print("[HomeViewModel] Toggling Live Listen to \(enabled)")
        do {
            let audioSession = AVAudioSession.sharedInstance()

            if enabled {
                try audioSession.setCategory(.playAndRecord,
                                            mode: .default,
                                            options: [.allowBluetooth, .allowBluetoothA2DP, .mixWithOthers])
                try audioSession.setActive(true)

                if let hearingInput = audioSession.availableInputs?.first(where: { input in
                    input.portType == .bluetoothHFP ||
                    input.portType == .bluetoothLE ||
                    input.portName.lowercased().contains("hearing")
                }) {
                    try audioSession.setPreferredInput(hearingInput)
                    print("[HomeViewModel] Preferred input set to hearing device: \(hearingInput.portName)")
                } else if let firstInput = audioSession.availableInputs?.first {
                    try audioSession.setPreferredInput(firstInput)
                    print("[HomeViewModel] Preferred input set to: \(firstInput.portName)")
                }

                print("[HomeViewModel] Live Listen enabled")
                print("[HomeViewModel] Current route: \(audioSession.currentRoute)")
                liveListenManager.start()
            } else {
                try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
                print("[HomeViewModel] Live Listen disabled")
                liveListenManager.stop()
            }
        } catch {
            print("[HomeViewModel] Error toggling Live Listen: \(error.localizedDescription)")
            errorMessage = "Failed to toggle Live Listen: \(error.localizedDescription)"
            showError = true
            isLiveListenOn = false
        }
    }
    
    deinit {
        print("[HomeViewModel] Deinitialized")
    }
}