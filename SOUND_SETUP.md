# Focus Flow - Sound Files Setup Guide

## Adding Ambient Sounds to Your App

To enable ambient sounds in Focus Flow, you need to add sound files to your Xcode project.

### Required Sound Files

Place the following `.m4a` files in your project:

#### Nature Sounds
- `rain_forest.m4a` - Gentle rainfall in a lush forest
- `ocean_waves.m4a` - Rhythmic ocean waves on a peaceful shore
- `thunderstorm.m4a` - Distant thunder with gentle rain
- `birds_chirping.m4a` - Morning bird songs in nature

#### Urban Sounds
- `coffee_shop.m4a` - Cozy coffee shop atmosphere
- `library_ambience.m4a` - Quiet library with subtle background sounds

#### White Noise
- `white_noise.m4a` - Pure white noise for concentration
- `pink_noise.m4a` - Soft pink noise for relaxation

#### Focus Mode Sounds
- `deep_space.m4a` - Cosmic ambience for deep work
- `aurora_waves.m4a` - Mystical aurora sounds for creativity
- `zen_garden.m4a` - Peaceful zen garden atmosphere
- `energetic_beats.m4a` - Motivating rhythmic beats

### How to Add Sound Files

1. **Prepare your sound files**
   - Format: `.m4a` (recommended for iOS/macOS)
   - Duration: Loop-friendly (30 seconds to 2 minutes)
   - Quality: 128-256 kbps AAC

2. **Add to Xcode Project**
   - Drag and drop the `.m4a` files into your Xcode project
   - Select "Copy items if needed"
   - Add to target: Focus Flow
   - The files should appear in your project navigator

3. **Verify Bundle Resources**
   - Select your project in Xcode
   - Go to "Build Phases" → "Copy Bundle Resources"
   - Ensure all `.m4a` files are listed

### Where to Find Sound Files

You can create or source ambient sounds from:

1. **Free Resources**
   - freesound.org (CC licensed sounds)
   - zapsplat.com (free with account)
   - soundbible.com

2. **Create Your Own**
   - Use GarageBand or Logic Pro
   - Record natural ambience
   - Generate white/pink noise

3. **Purchase Premium Sounds**
   - AudioJungle
   - Pond5
   - Premium sound libraries

### Sound File Guidelines

- **File Size**: Keep under 5MB per file
- **Looping**: Ensure smooth loop points
- **Volume**: Normalize to -12dB to -6dB
- **Fade**: Add 0.5s fade in/out for smooth transitions

### Testing

The app will gracefully handle missing sounds:
- Shows alert when sound file is missing
- Lists available sounds in the UI
- Falls back to available sounds

### Troubleshooting

If sounds don't play:
1. Check file is in Bundle Resources
2. Verify file name matches exactly (case-sensitive)
3. Ensure `.m4a` format
4. Check audio session permissions