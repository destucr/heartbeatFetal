//
//  LiveListenManager.swift
//  Tiny
//
//  Created by Destu Cikal Ramdani on 30/09/25.
//

import Foundation
import AVFoundation
import Combine

class LiveListenManager {
    private var audioEngine = AVAudioEngine()
    @Published var currentOutputDeviceName: String? = nil

    func start() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.allowBluetooth, .defaultToSpeaker])
            
            guard let builtInMic = AVAudioSession.sharedInstance().availableInputs?.first(where: {
                $0.portType == .builtInMic
            }) else {
                print("Built-in mic not found")
                return
            }
            
            try audioSession.setPreferredInput(builtInMic)
            try audioSession.setActive(true)
            currentOutputDeviceName = audioSession.currentRoute.outputs.first?.portName

            let inputNode = audioEngine.inputNode
            let outputNode = audioEngine.outputNode
            let format = inputNode.outputFormat(forBus: 0)

            audioEngine.connect(inputNode, to: outputNode, format: format)

            try audioEngine.start()
        } catch {
            print("Error starting audio engine: \(error.localizedDescription)")
        }
    }

    func stop() {
        audioEngine.stop()
        audioEngine.reset()
        currentOutputDeviceName = nil
    }
}

