import AVFoundation
import SwiftUI
import UIKit
import Combine

class AmbientSoundManager: ObservableObject {
    @Published var isPlaying = false
    @Published var currentSound: AmbientSound?
    @Published var volume: Float = 0.7
    @Published var mixedSounds: [AmbientSound] = []
    @Published var selectedSounds: Set<String> = []
    
    private var audioPlayers: [String: AVAudioPlayer] = [:]
    private var audioEngine = AVAudioEngine()
    private var mixerNode = AVAudioMixerNode()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupAudioSession()
        setupAudioEngine()
        preloadCommonSounds()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    private func setupAudioEngine() {
        audioEngine.attach(mixerNode)
        audioEngine.connect(mixerNode, to: audioEngine.mainMixerNode, format: nil)
        
        do {
            try audioEngine.start()
        } catch {
            print("Failed to start audio engine: \(error)")
        }
    }
    
    func playSound(_ sound: AmbientSound, fadeIn: Bool = true) {
        stopAllSounds(fadeOut: false)
        
        guard let url = Bundle.main.url(forResource: sound.fileName, withExtension: "m4a") else {
            print("Sound file not found: \(sound.fileName)")
            return
        }
        
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1
            player.volume = fadeIn ? 0 : volume
            player.prepareToPlay()
            
            audioPlayers[sound.id] = player
            player.play()
            
            if fadeIn {
                fadeVolume(for: player, to: volume, duration: 2.0)
            }
            
            currentSound = sound
            isPlaying = true
            HapticStyle.light.trigger()
        } catch {
            print("Failed to play sound: \(error)")
        }
    }
    
    func stopAllSounds(fadeOut: Bool = true) {
        if fadeOut && !audioPlayers.isEmpty {
            for player in audioPlayers.values {
                fadeVolume(for: player, to: 0, duration: 1.0) { [weak self] in
                    player.stop()
                    DispatchQueue.main.async {
                        self?.audioPlayers.removeAll()
                        self?.isPlaying = false
                        self?.currentSound = nil
                        self?.selectedSounds.removeAll()
                    }
                }
            }
        } else {
            audioPlayers.values.forEach { $0.stop() }
            audioPlayers.removeAll()
            isPlaying = false
            currentSound = nil
            selectedSounds.removeAll()
        }
    }
    
    func toggleSound(_ sound: AmbientSound) {
        if selectedSounds.contains(sound.id) {
            removeSound(sound)
        } else {
            addSound(sound)
        }
    }
    
    func addSound(_ sound: AmbientSound) {
        guard !selectedSounds.contains(sound.id) else { return }
        guard let url = Bundle.main.url(forResource: sound.fileName, withExtension: "m4a") else { return }
        
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1
            player.volume = sound.defaultVolume * volume
            player.prepareToPlay()
            player.play()
            
            audioPlayers[sound.id] = player
            selectedSounds.insert(sound.id)
            isPlaying = true
            
            fadeVolume(for: player, to: sound.defaultVolume * volume, duration: 1.0)
            HapticStyle.light.trigger()
        } catch {
            print("Failed to add sound: \(error)")
        }
    }
    
    func removeSound(_ sound: AmbientSound) {
        guard selectedSounds.contains(sound.id),
              let player = audioPlayers[sound.id] else { return }
        
        fadeVolume(for: player, to: 0, duration: 1.0) { [weak self] in
            player.stop()
            self?.audioPlayers.removeValue(forKey: sound.id)
            self?.selectedSounds.remove(sound.id)
            
            if self?.audioPlayers.isEmpty == true {
                self?.isPlaying = false
                self?.currentSound = nil
            }
        }
        HapticStyle.light.trigger()
    }
    
    func updateVolume(_ newVolume: Float) {
        volume = newVolume
        for (soundId, player) in audioPlayers {
            if let sound = AmbientSound.library.first(where: { $0.id == soundId }) {
                player.volume = sound.defaultVolume * volume
            }
        }
    }
    
    func playMoodSet(_ moodSet: AmbientMoodSet) {
        stopAllSounds(fadeOut: false)
        
        for sound in moodSet.sounds {
            addSound(sound)
        }
        
        currentSound = moodSet.sounds.first
        HapticStyle.success.trigger()
    }
    
    // Convenience methods for the UI
    func play(sound: AmbientSound) {
        playSound(sound)
    }
    
    func stop() {
        stopAllSounds()
    }
    
    private func fadeVolume(for player: AVAudioPlayer, to targetVolume: Float, duration: TimeInterval, completion: (() -> Void)? = nil) {
        let steps = 20
        let stepDuration = duration / Double(steps)
        let volumeStep = (targetVolume - player.volume) / Float(steps)
        var currentStep = 0
        
        Timer.scheduledTimer(withTimeInterval: stepDuration, repeats: true) { timer in
            currentStep += 1
            player.volume += volumeStep
            
            if currentStep >= steps {
                timer.invalidate()
                player.volume = targetVolume
                completion?()
            }
        }
    }
    
    func preloadSound(_ soundName: String) {
        guard let url = Bundle.main.url(forResource: soundName, withExtension: "m4a") else { return }
        
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            audioPlayers["preload_\(soundName)"] = player
        } catch {
            print("Failed to preload sound: \(error)")
        }
    }
    
    private func preloadCommonSounds() {
        let commonSounds = ["rain_forest", "ocean_waves", "white_noise", "coffee_shop", "thunderstorm", "birds_chirping"]
        commonSounds.forEach { preloadSound($0) }
    }
    
    // MARK: - Focus Mode Integration
    
    func soundForFocusMode(_ mode: FocusMode) -> AmbientSound? {
        switch mode {
        case .deepWork:
            return AmbientSound.library.first { $0.name == "Deep Space" }
        case .creativeFlow:
            return AmbientSound.library.first { $0.name == "Aurora Waves" }
        case .learning:
            return AmbientSound.library.first { $0.name == "Library Ambience" }
        case .quickSprint:
            return AmbientSound.library.first { $0.name == "Energetic Beats" }
        case .mindfulFocus:
            return AmbientSound.library.first { $0.name == "Zen Garden" }
        }
    }
}

// MARK: - Ambient Sound Model

struct AmbientSound: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let fileName: String
    let category: SoundCategory
    let icon: String
    let defaultVolume: Float
    let isPremium: Bool
    let description: String
    let duration: TimeInterval?
    
    enum SoundCategory: String, CaseIterable, Codable {
        case nature, urban, white, binaural, musical, meditation
        
        var displayName: String {
            switch self {
            case .nature: return "Nature"
            case .urban: return "Urban"
            case .white: return "White Noise"
            case .binaural: return "Binaural Beats"
            case .musical: return "Musical"
            case .meditation: return "Meditation"
            }
        }
        
        var color: Color {
            switch self {
            case .nature: return .green
            case .urban: return .blue
            case .white: return .gray
            case .binaural: return .purple
            case .musical: return .orange
            case .meditation: return .mint
            }
        }
        
        var icon: String {
            switch self {
            case .nature: return "leaf.fill"
            case .urban: return "building.2.fill"
            case .white: return "waveform"
            case .binaural: return "brain.head.profile"
            case .musical: return "music.note"
            case .meditation: return "figure.seated.side"
            }
        }
    }
    
    static let library: [AmbientSound] = [
        // Nature Sounds
        AmbientSound(
            id: UUID().uuidString,
            name: "Rain Forest",
            fileName: "rain_forest",
            category: .nature,
            icon: "cloud.rain.fill",
            defaultVolume: 0.7,
            isPremium: false,
            description: "Gentle rainfall in a lush forest",
            duration: nil
        ),
        AmbientSound(
            id: UUID().uuidString,
            name: "Ocean Waves",
            fileName: "ocean_waves",
            category: .nature,
            icon: "wind",
            defaultVolume: 0.6,
            isPremium: false,
            description: "Rhythmic ocean waves on a peaceful shore",
            duration: nil
        ),
        AmbientSound(
            id: UUID().uuidString,
            name: "Thunderstorm",
            fileName: "thunderstorm",
            category: .nature,
            icon: "cloud.bolt.rain.fill",
            defaultVolume: 0.5,
            isPremium: true,
            description: "Distant thunder with gentle rain",
            duration: nil
        ),
        AmbientSound(
            id: UUID().uuidString,
            name: "Birds Chirping",
            fileName: "birds_chirping",
            category: .nature,
            icon: "bird.fill",
            defaultVolume: 0.8,
            isPremium: false,
            description: "Morning bird songs in nature",
            duration: nil
        ),
        
        // Urban Sounds
        AmbientSound(
            id: UUID().uuidString,
            name: "Coffee Shop",
            fileName: "coffee_shop",
            category: .urban,
            icon: "cup.and.saucer.fill",
            defaultVolume: 0.6,
            isPremium: false,
            description: "Cozy coffee shop atmosphere",
            duration: nil
        ),
        AmbientSound(
            id: UUID().uuidString,
            name: "Library Ambience",
            fileName: "library_ambience",
            category: .urban,
            icon: "book.fill",
            defaultVolume: 0.4,
            isPremium: true,
            description: "Quiet library with subtle background sounds",
            duration: nil
        ),
        
        // White Noise
        AmbientSound(
            id: UUID().uuidString,
            name: "White Noise",
            fileName: "white_noise",
            category: .white,
            icon: "waveform",
            defaultVolume: 0.5,
            isPremium: false,
            description: "Pure white noise for concentration",
            duration: nil
        ),
        AmbientSound(
            id: UUID().uuidString,
            name: "Pink Noise",
            fileName: "pink_noise",
            category: .white,
            icon: "waveform.badge.plus",
            defaultVolume: 0.5,
            isPremium: true,
            description: "Soft pink noise for relaxation",
            duration: nil
        ),
        
        // Focus Mode Sounds
        AmbientSound(
            id: UUID().uuidString,
            name: "Deep Space",
            fileName: "deep_space",
            category: .meditation,
            icon: "sparkles",
            defaultVolume: 0.6,
            isPremium: true,
            description: "Cosmic ambience for deep work",
            duration: nil
        ),
        AmbientSound(
            id: UUID().uuidString,
            name: "Aurora Waves",
            fileName: "aurora_waves",
            category: .meditation,
            icon: "cloud.heavyrain.fill",
            defaultVolume: 0.7,
            isPremium: true,
            description: "Mystical aurora sounds for creativity",
            duration: nil
        ),
        AmbientSound(
            id: UUID().uuidString,
            name: "Zen Garden",
            fileName: "zen_garden",
            category: .meditation,
            icon: "leaf.circle.fill",
            defaultVolume: 0.5,
            isPremium: true,
            description: "Peaceful zen garden atmosphere",
            duration: nil
        ),
        AmbientSound(
            id: UUID().uuidString,
            name: "Energetic Beats",
            fileName: "energetic_beats",
            category: .musical,
            icon: "bolt.circle.fill",
            defaultVolume: 0.8,
            isPremium: true,
            description: "Motivating rhythmic beats",
            duration: nil
        )
    ]
    
    static func categorized() -> [SoundCategory: [AmbientSound]] {
        return Dictionary(grouping: library, by: { $0.category })
    }
    
    static func freeSounds() -> [AmbientSound] {
        return library.filter { !$0.isPremium }
    }
    
    static func premiumSounds() -> [AmbientSound] {
        return library.filter { $0.isPremium }
    }
}

// MARK: - Ambient Mood Sets

struct AmbientMoodSet: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let sounds: [AmbientSound]
    let icon: String
    let isPremium: Bool
    
    static let presets: [AmbientMoodSet] = [
        AmbientMoodSet(
            name: "Forest Sanctuary",
            description: "Rain forest with distant thunderstorm",
            sounds: [
                AmbientSound.library.first { $0.name == "Rain Forest" }!,
                AmbientSound.library.first { $0.name == "Thunderstorm" }!
            ],
            icon: "tree.fill",
            isPremium: true
        ),
        AmbientMoodSet(
            name: "Coastal Cafe",
            description: "Ocean waves with coffee shop ambience",
            sounds: [
                AmbientSound.library.first { $0.name == "Ocean Waves" }!,
                AmbientSound.library.first { $0.name == "Coffee Shop" }!
            ],
            icon: "beach.umbrella.fill",
            isPremium: false
        ),
        AmbientMoodSet(
            name: "Study Hall",
            description: "Library ambience with subtle white noise",
            sounds: [
                AmbientSound.library.first { $0.name == "Library Ambience" }!,
                AmbientSound.library.first { $0.name == "White Noise" }!
            ],
            icon: "studentdesk",
            isPremium: true
        )
    ]
}

 