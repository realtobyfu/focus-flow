import Foundation
import Intents

// This is a custom intent that would normally be defined in your app's intents definition file
// For demo purposes, we're creating a simple version here
class ConfigureFocusModeIntent: INIntent {
    var mode: String?
    var isEnabled: Bool = false
} 