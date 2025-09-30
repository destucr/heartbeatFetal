//
//  ContentView.swift
//  heartbeatFetal
//
//  Created by Destu Cikal Ramdani on 30/09/25.
//

import SwiftUI
import AVFoundation
import Combine
import Accessibility

struct HearingDevice: Identifiable, Hashable {
    let id: UUID
    let name: String
    var isConnected: Bool
}

struct ContentView: View {
    @StateObject private var hearingDeviceManager = HearingDeviceManager()
    @State private var selectedDevice: HearingDevice?
    @State private var isLiveListenOn = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Device List
                if hearingDeviceManager.devices.isEmpty {
                    VStack {
                        Image(systemName: "ear.trianglebadge.exclamationmark")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("No hearing devices found")
                            .foregroundColor(.gray)
                            .padding()
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    List {
                        ForEach(hearingDeviceManager.devices) { device in
                            Button(action: {
                                self.selectedDevice = device
                            }) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(device.name)
                                            .font(.headline)
                                        Text(device.isConnected ? "Connected" : "Paired")
                                            .font(.caption)
                                            .foregroundColor(device.isConnected ? .green : .orange)
                                    }
                                    Spacer()
                                    if self.selectedDevice?.id == device.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.blue)
                                    }
                                    if device.isConnected {
                                        Circle()
                                            .fill(Color.green)
                                            .frame(width: 10, height: 10)
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Selected Device Info
                if let selectedDevice = selectedDevice {
                    VStack(spacing: 10) {
                        Text("Selected Device")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(selectedDevice.name)
                            .font(.headline)
                        
                        HStack {
                            Circle()
                                .fill(selectedDevice.isConnected ? Color.green : Color.red)
                                .frame(width: 12, height: 12)
                            Text(selectedDevice.isConnected ? "Connected" : "Disconnected")
                                .foregroundColor(selectedDevice.isConnected ? .green : .red)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
                
                // Scan Button
                Button(action: {
                    hearingDeviceManager.scanForDevices()
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Scan for Devices")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                
                // Live Listen Toggle
                VStack {
                    Toggle(isOn: $isLiveListenOn) {
                        HStack {
                            Image(systemName: "ear")
                            Text("Live Listen")
                                .font(.headline)
                        }
                    }
                    .disabled(!isDeviceConnected())
                    .onChange(of: isLiveListenOn) { oldValue, newValue in
                        toggleLiveListen(enabled: newValue)
                    }
                    
                    if !isDeviceConnected() {
                        Text("Select a connected device to enable Live Listen")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
            }
            .navigationTitle("Hearing Devices")
            .onAppear {
                hearingDeviceManager.scanForDevices()
                requestMicrophonePermission()
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func isDeviceConnected() -> Bool {
        return selectedDevice?.isConnected ?? false
    }
    
    private func requestMicrophonePermission() {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            if !granted {
                DispatchQueue.main.async {
                    errorMessage = "Microphone access is required for Live Listen"
                    showError = true
                }
            }
        }
    }
    
    private func toggleLiveListen(enabled: Bool) {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            
            if enabled {
                try audioSession.setCategory(.playAndRecord, mode: .default, options: [.allowBluetooth, .allowBluetoothA2DP])
                try audioSession.setActive(true)
                
                // Configure audio session for live listen
                try audioSession.setPreferredInput(audioSession.availableInputs?.first)
                
                print("Live Listen enabled")
            } else {
                try audioSession.setActive(false)
                print("Live Listen disabled")
            }
        } catch {
            errorMessage = "Failed to toggle Live Listen: \(error.localizedDescription)"
            showError = true
            isLiveListenOn = false
        }
    }
}

// Manager class to handle hearing devices
class HearingDeviceManager: ObservableObject {

    @Published var devices: [HearingDevice] = []
    
    init() {
        // Set up notification observers for device changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioRouteChange),
            name: AVAudioSession.routeChangeNotification,
            object: nil
        )
    }
    
    func scanForDevices() {
        var foundDevices: [HearingDevice] = []
        
        // Check for MFi hearing devices using Accessibility framework
        // Note: This requires proper entitlements and may need additional setup
        #if !targetEnvironment(simulator)
        if let pairedUUIDs = AXMFiHearingDevice.pairedDeviceIdentifiers() as? [UUID] {
            for uuid in pairedUUIDs {
                let device = HearingDevice(
                    id: uuid,
                    name: "Hearing Device \(uuid.uuidString.prefix(8))",
                    isConnected: isDeviceConnected(uuid: uuid)
                )
                foundDevices.append(device)
            }
        }
        #endif
        
        // Also check for Bluetooth audio devices
        let audioSession = AVAudioSession.sharedInstance()
        if let availableInputs = audioSession.availableInputs {
            for input in availableInputs {
                if input.portType == .bluetoothHFP || input.portType == .bluetoothA2DP || input.portType == .bluetoothLE {
                    let device = HearingDevice(
                        id: UUID(),
                        name: input.portName,
                        isConnected: audioSession.currentRoute.inputs.contains(input)
                    )
                    foundDevices.append(device)
                }
            }
        }
        

        
        DispatchQueue.main.async {
            self.devices = foundDevices
        }
    }
    
    private func isDeviceConnected(uuid: UUID) -> Bool {
        // Check connection status
        // This is a simplified check. A more robust implementation would involve
        // checking the connection status of the specific MFi device.
        let audioSession = AVAudioSession.sharedInstance()
        return !audioSession.currentRoute.outputs.isEmpty
    }
    
    @objc private func handleAudioRouteChange(notification: Notification) {
        // Refresh device list when audio route changes
        scanForDevices()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

#Preview {
    ContentView()
}

