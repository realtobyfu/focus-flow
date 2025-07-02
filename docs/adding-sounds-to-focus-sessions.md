# Adding Sounds to Focus Sessions

This guide explains how to integrate notification sounds and ambient sounds into Focus Flow's timer system.

## Overview

Focus Flow uses two types of sounds:
1. **Ambient Sounds** - Background sounds that play during focus sessions
2. **Notification Sounds** - Short sounds for timer events (start, pause, phase transitions)

## Current Sound Architecture

### AmbientSoundManager
Located at `Focus Flow/Managers/AmbientSoundManager.swift`, this class handles:
- Playing looped ambient sounds during focus sessions
- Volume control and fade in/out effects
- Sound file validation and error handling
- Integration with device audio sessions

### Sound Files
- Format: `.m4a` files
- Location: App bundle resources
- Current ambient sounds: rain, forest, ocean, white_noise, brown_noise, etc.

## Adding Notification Sounds

### 1. Create NotificationSoundManager

Create a new file `Focus Flow/Managers/NotificationSoundManager.swift`:

```swift
import AVFoundation
import SwiftUI

class NotificationSoundManager: ObservableObject {
    static let shared = NotificationSoundManager()
    
    private var audioPlayer: AVAudioPlayer?
    
    enum SoundType: String, CaseIterable {
        case timerStart = "timer_start"
        case timerPause = "timer_pause"
        case phaseComplete = "phase_complete"
        case sessionComplete = "session_complete"
        
        var systemFallback: UInt32 {
            switch self {
            case .timerStart: return 1054  // Begin Recording
            case .timerPause: return 1055  // End Recording
            case .phaseComplete: return 1256  // Bloom
            case .sessionComplete: return 1025  // Glass
            }
        }
    }
    
    func playSound(_ type: SoundType) {
        // First try custom sound
        if let url = Bundle.main.url(forResource: type.rawValue, withExtension: "m4a") {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: url)
                audioPlayer?.play()
            } catch {
                // Fall back to system sound
                AudioServicesPlaySystemSound(type.systemFallback)
            }
        } else {
            // Use system sound if custom sound not found
            AudioServicesPlaySystemSound(type.systemFallback)
        }
    }
}
```

### 2. Add Sound Assets

Add the following `.m4a` files to your Xcode project:
- `timer_start.m4a` - Pleasant chime for timer start
- `timer_pause.m4a` - Soft pause indication  
- `phase_complete.m4a` - Achievement sound for completing focus/break
- `session_complete.m4a` - Celebration sound for full session completion

### 3. Update TimerView

Modify `Focus Flow/Views/TimerView.swift` to integrate notification sounds:

```swift
// Add to TimerView
@StateObject private var notificationSoundManager = NotificationSoundManager.shared

// In startTimer() function, add:
notificationSoundManager.playSound(.timerStart)

// In pauseTimer() function, add:
notificationSoundManager.playSound(.timerPause)

// When phase completes (switching between focus/break):
notificationSoundManager.playSound(.phaseComplete)

// When entire session completes:
notificationSoundManager.playSound(.sessionComplete)
```

## Controlling Ambient Sounds During Breaks

### Update TimerView for Phase-Based Sound Control

Modify the ambient sound logic in `TimerView.swift`:

```swift
// In TimerView, update the sound control logic:
private func updateAmbientSound() {
    if currentPhase == .focus && soundEnabled {
        // Play ambient sound during focus phase
        if let selectedSound = ambientSoundManager.selectedSound {
            ambientSoundManager.playSound(selectedSound)
        }
    } else {
        // Stop ambient sound during break phase
        ambientSoundManager.stopSound()
    }
}

// Call this when phase changes:
.onChange(of: currentPhase) { _ in
    updateAmbientSound()
}
```

## Adding Sound Settings

### Update SettingsView

Add these settings to `Focus Flow/Views/SettingsView.swift`:

```swift
// Timer Sounds Section
Section(header: Text("Timer Sounds")) {
    Toggle("Notification Sounds", isOn: $notificationSoundsEnabled)
    
    if notificationSoundsEnabled {
        HStack {
            Text("Volume")
            Slider(value: $notificationVolume, in: 0...1)
        }
        
        // Preview sounds
        ForEach(NotificationSoundManager.SoundType.allCases, id: \.self) { soundType in
            Button(action: {
                notificationSoundManager.playSound(soundType)
            }) {
                HStack {
                    Text(soundType.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
                    Spacer()
                    Image(systemName: "play.circle")
                }
            }
        }
    }
    
    Toggle("Play Ambient Sounds During Breaks", isOn: $playAmbientDuringBreaks)
}
```

## Implementation Tips

### 1. Volume Mixing
Ensure notification sounds are audible over ambient sounds:
```swift
// In NotificationSoundManager
audioPlayer?.volume = 0.8  // Slightly louder than ambient
```

### 2. Haptic Feedback
Add haptic feedback alongside sounds:
```swift
import UIKit

private func playHaptic() {
    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
    impactFeedback.impactOccurred()
}
```

### 3. Background Audio
Ensure sounds work when app is in background:
```swift
// In Info.plist, add UIBackgroundModes: audio
// Configure audio session for background playback
```

### 4. Sound File Guidelines
- Keep notification sounds short (< 2 seconds)
- Use consistent volume levels
- Test with different device volumes
- Provide system sound fallbacks

## Testing

1. Test all sound combinations (ambient + notification)
2. Verify sounds play at correct timer events
3. Test with silent mode and Do Not Disturb
4. Ensure proper cleanup when timer stops
5. Test background audio behavior

## Troubleshooting

### Common Issues:
1. **Sounds not playing**: Check file names and bundle resources
2. **Volume too low**: Adjust AVAudioPlayer volume
3. **Sounds overlapping**: Implement proper audio session management
4. **Background audio stops**: Configure proper background modes

### Debug Helper:
```swift
// Add to NotificationSoundManager for debugging
func listAvailableSounds() {
    print("Available notification sounds:")
    for type in SoundType.allCases {
        if Bundle.main.url(forResource: type.rawValue, withExtension: "m4a") != nil {
            print("✓ \(type.rawValue)")
        } else {
            print("✗ \(type.rawValue) (will use system sound)")
        }
    }
}
```

## Future Enhancements

1. **Custom Sound Packs**: Allow users to choose different sound themes
2. **Adaptive Sounds**: Different sounds based on focus mode
3. **Smart Volume**: Auto-adjust based on ambient noise
4. **Sound Shortcuts**: Let users record custom sounds
5. **Accessibility**: Visual indicators for hearing-impaired users