// MARK: - Info.plist Configuration

/*
Add to Info.plist:

<key>BGTaskSchedulerPermittedIdentifiers</key>
<array>
    <string>com.flowstate.refresh</string>
    <string>com.flowstate.cleanup</string>
</array>

<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>processing</string>
    <string>audio</string>
</array>

<key>NSUserNotificationsUsageDescription</key>
<string>Flow State sends notifications to remind you to take breaks and celebrate your achievements.</string>

<key>NSCameraUsageDescription</key>
<string>Flow State needs camera access to let you customize your profile picture.</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>Flow State needs photo library access to let you customize your profile picture.</string>

<key>NSMicrophoneUsageDescription</key>
<string>Flow State needs microphone access for voice notes in focus sessions.</string>

<key>ITSAppUsesNonExemptEncryption</key>
<false/>

<key>LSApplicationQueriesSchemes</key>
<array>
    <string>instagram</string>
    <string>twitter</string>
    <string>facebook</string>
</array>

<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>flowstate</string>
        </array>
        <key>CFBundleURLName</key>
        <string>com.flowstate.app</string>
    </dict>
</array>
*/

## 27. Testing Setup

```swift
// Tests/FlowStateTests.swift
import XCTest
@testable import Flow_State

class FlowStateTests: XCTestCase {
    var taskViewModel: TaskViewModel!
    var mockContext: NSManagedObjectContext!
    
    override func setUpWithError() throws {
        // Setup in-memory Core Data stack
        mockContext = PersistenceController(inMemory: true).container.viewContext
        taskViewModel = TaskViewModel(context: mockContext)
    }
    
    override func tearDownWithError() throws {
        taskViewModel = nil
        mockContext = nil
    }
    
    // MARK: - Task Tests
    
    func testCreateTask() throws {
        // Given
        let taskTitle = "Test Task"
        let duration: Int64 = 25
        
        // When
        taskViewModel.createTask(
            title: taskTitle,
            totalMinutes: duration,
            blockMinutes: duration,
            breakMinutes: 5
        )
        
        // Then
        XCTAssertEqual(taskViewModel.tasks.count, 1)
        XCTAssertEqual(taskViewModel.tasks.first?.title, taskTitle)
    }
    
    func testUpdateTaskProgress() throws {
        // Given
        taskViewModel.createTask(
            title: "Test",
            totalMinutes: 60,
            blockMinutes: 25,
            breakMinutes: 5
        )
        let task = taskViewModel.tasks.first!
        
        // When
        taskViewModel.updateTaskProgress(task, completedMinutes: 25)
        
        // Then
        XCTAssertEqual(task.completionPercentage, 41.67, accuracy: 0.01)
    }
    
    // MARK: - AI Recommendation Tests
    
    func testRecommendationGeneration() async throws {
        // Given
        let recommender = AISessionRecommender()
        
        // When
        recommender.analyzeAndRecommend()
        
        // Wait for async operation
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Then
        XCTAssertNotNil(recommender.recommendation)
        XCTAssertGreaterThan(recommender.recommendation!.confidenceScore, 0)
    }
    
    // MARK: - Achievement Tests
    
    func testAchievementUnlock() throws {
        // Given
        let manager = AchievementManager()
        let initialCount = manager.unlockedAchievements.count
        
        // When
        manager.checkAchievements(for: .sessionCompleted(
            duration: 25,
            mode: .deepWork,
            totalCount: 1,
            time: Date()
        ))
        
        // Then
        XCTAssertGreaterThan(manager.unlockedAchievements.count, initialCount)
    }
    
    // MARK: - Premium Store Tests
    
    func testPremiumFeatureCheck() throws {
        // Given
        let featuresManager = PremiumFeaturesManager()
        
        // When
        let isLocked = featuresManager.requiresPremium(for: .aiInsights)
        
        // Then
        XCTAssertTrue(isLocked) // Should be locked by default
    }
}

// MARK: - UI Tests

class FlowStateUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    func testOnboardingFlow() throws {
        // Test onboarding appears on first launch
        XCTAssertTrue(app.staticTexts["Welcome to\nFlow State"].exists)
        
        // Continue through onboarding
        app.buttons["Get Started"].tap()
        
        // Test goal selection
        XCTAssertTrue(app.staticTexts["What brings you here?"].exists)
    }
    
    func testStartFocusSession() throws {
        // Skip onboarding if needed
        skipOnboardingIfPresent()
        
        // Start a focus session
        app.buttons["Start Focus"].tap()
        
        // Verify timer is running
        XCTAssertTrue(app.staticTexts["25:00"].exists)
    }
    
    private func skipOnboardingIfPresent() {
        if app.buttons["Skip"].exists {
            app.buttons["Skip"].tap()
        }
    }
}

## 28. CI/CD Configuration

```yaml
# .github/workflows/ios.yml
name: iOS CI/CD

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    name: Test
    runs-on: macos-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Select Xcode
      run: sudo xcode-select -switch /Applications/Xcode_15.0.app
      
    - name: Install Dependencies
      run: |
        brew install swiftlint
        
    - name: Lint
      run: swiftlint
      
    - name: Build and Test
      run: |
        xcodebuild clean build test \
          -project "Focus Flow.xcodeproj" \
          -scheme "Focus Flow" \
          -sdk iphonesimulator \
          -destination "platform=iOS Simulator,OS=17.0,name=iPhone 15" \
          ONLY_ACTIVE_ARCH=NO \
          CODE_SIGNING_REQUIRED=NO
          
  build:
    name: Build for TestFlight
    runs-on: macos-latest
    if: github.ref == 'refs/heads/main'
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Install Certificates
      env:
        CERTIFICATES_P12: ${{ secrets.CERTIFICATES_P12 }}
        CERTIFICATES_PASSWORD: ${{ secrets.CERTIFICATES_PASSWORD }}
        KEYCHAIN_PASSWORD: ${{ secrets.KEYCHAIN_PASSWORD }}
      run: |
        # Create temporary keychain
        security create-keychain -p "$KEYCHAIN_PASSWORD" build.keychain
        security default-keychain -s build.keychain
        security unlock-keychain -p "$KEYCHAIN_PASSWORD" build.keychain
        
        # Import certificates
        echo $CERTIFICATES_P12 | base64 --decode > certificate.p12
        security import certificate.p12 -k build.keychain -P "$CERTIFICATES_PASSWORD" -T /usr/bin/codesign
        
    - name: Install Provisioning Profile
      env:
        PROVISIONING_PROFILE: ${{ secrets.PROVISIONING_PROFILE }}
      run: |
        echo $PROVISIONING_PROFILE | base64 --decode > profile.mobileprovision
        mkdir -p ~/Library/MobileDevice/Provisioning\ Profiles
        cp profile.mobileprovision ~/Library/MobileDevice/Provisioning\ Profiles/
        
    - name: Build Archive
      run: |
        xcodebuild -project "Focus Flow.xcodeproj" \
          -scheme "Focus Flow" \
          -sdk iphoneos \
          -configuration Release \
          -archivePath $PWD/build/FlowState.xcarchive \
          clean archive
          
    - name: Export IPA
      run: |
        xcodebuild -exportArchive \
          -archivePath $PWD/build/FlowState.xcarchive \
          -exportPath $PWD/build \
          -exportOptionsPlist ExportOptions.plist
          
    - name: Upload to TestFlight
      env:
        APP_STORE_CONNECT_API_KEY: ${{ secrets.APP_STORE_CONNECT_API_KEY }}
      run: |
        xcrun altool --upload-app \
          --type ios \
          --file build/FlowState.ipa \
          --apiKey "$APP_STORE_CONNECT_API_KEY"

# ExportOptions.plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
    <key>uploadSymbols</key>
    <true/>
    <key>compileBitcode</key>
    <false/>
</dict>
</plist>
