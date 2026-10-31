import Foundation
import CoreAudio
import AudioToolbox
import Combine

public final class AudioService: ObservableObject {
    public static let shared = AudioService()
    
    @Published public private(set) var volume: Float = 0.5
    @Published public private(set) var isMuted: Bool = false
    
    public var onVolumeChanged: ((Float, Bool) -> Void)?
    
    private var defaultOutputDeviceID: AudioDeviceID = 0
    private var isObserving: Bool = false
    
    private init() {
        setupAudioMonitoring()
    }
    
    deinit {
        teardownAudioMonitoring()
    }
    
    private func setupAudioMonitoring() {
        defaultOutputDeviceID = getDefaultOutputDeviceID()
        guard defaultOutputDeviceID != 0 else { return }
        
        updateCurrentVolume()
        
        // Listen for volume changes on the default device
        var volumePropertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwareServiceDeviceProperty_VirtualMainVolume,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        
        let context = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        let status = AudioObjectAddPropertyListener(
            defaultOutputDeviceID,
            &volumePropertyAddress,
            { (inObjectID, inNumberAddresses, inAddresses, inClientData) -> OSStatus in
                guard let inClientData = inClientData else { return noErr }
                let service = Unmanaged<AudioService>.fromOpaque(inClientData).takeUnretainedValue()
                service.handleVolumeChange()
                return noErr
            },
            context
        )
        
        if status == noErr {
            isObserving = true
        }
    }
    
    private func teardownAudioMonitoring() {
        guard isObserving, defaultOutputDeviceID != 0 else { return }
        var volumePropertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwareServiceDeviceProperty_VirtualMainVolume,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        let context = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        AudioObjectRemovePropertyListener(
            defaultOutputDeviceID,
            &volumePropertyAddress,
            { _, _, _, _ in noErr },
            context
        )
    }
    
    private func getDefaultOutputDeviceID() -> AudioDeviceID {
        var defaultOutputDeviceID = AudioDeviceID(0)
        var defaultOutputDeviceIDSize = UInt32(MemoryLayout.size(ofValue: defaultOutputDeviceID))
        var getDefaultOutputDevicePropertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &getDefaultOutputDevicePropertyAddress,
            0,
            nil,
            &defaultOutputDeviceIDSize,
            &defaultOutputDeviceID
        )

        return status == noErr ? defaultOutputDeviceID : 0
    }
    
    private func updateCurrentVolume() {
        guard defaultOutputDeviceID != 0 else { return }
        
        var vol: Float32 = 0.0
        var volSize = UInt32(MemoryLayout.size(ofValue: vol))
        var volumePropertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwareServiceDeviceProperty_VirtualMainVolume,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )

        let status = AudioObjectGetPropertyData(
            defaultOutputDeviceID,
            &volumePropertyAddress,
            0,
            nil,
            &volSize,
            &vol
        )

        if status == noErr {
            self.volume = vol
            self.isMuted = (vol <= 0.001)
        }
    }
    
    private func handleVolumeChange() {
        updateCurrentVolume()
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.onVolumeChanged?(self.volume, self.isMuted)
        }
    }
}

