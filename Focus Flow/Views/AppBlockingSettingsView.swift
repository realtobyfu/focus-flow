import SwiftUI
import FamilyControls

@available(iOS 15.0, *)
struct AppBlockingSettingsView: View {
    @EnvironmentObject var blockingManager: AppBlockingManager
    @StateObject private var networkService = NetworkBlockingService()
    
    @State private var showingFamilyActivityPicker = false
    @State private var showingScreenTimeAuth = false
    @State private var familyActivitySelection = FamilyActivitySelection()
    
    var body: some View {
        Form {
                // Authorization Section
                Section {
                    if !blockingManager.isScreenTimeConfigured {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Screen Time Required", systemImage: "exclamationmark.triangle")
                                .foregroundColor(.orange)
                            Text("Screen Time authorization is required for advanced app blocking features.")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            HStack {
                                Button("Request Authorization") {
                                    requestScreenTimeAuth()
                                }
                                .buttonStyle(.borderedProminent)

                                Button("Refresh Status") {
                                    blockingManager.refreshAuthorizationStatus()
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    } else {
                        HStack {
                            Label("Screen Time Authorized", systemImage: "checkmark.circle")
                                .foregroundColor(.green)

                            Spacer()

                            Button("Refresh", systemImage: "arrow.clockwise") {
                                blockingManager.refreshAuthorizationStatus()
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                } header: {
                    Text("Authorization")
                } footer: {
                    Text("If authorization status appears incorrect, tap refresh to check current status.")
                }
                
                // Blocking Level Section
                Section {
                    Picker("Blocking Level", selection: $blockingManager.blockingLevel) {
                        ForEach(AppBlockingManager.BlockingLevel.allCases, id: \.self) { level in
                            Text(level.rawValue).tag(level)
                        }
                    }
                    .pickerStyle(.menu)

                    // Show description for selected level
                    if !blockingManager.blockingLevel.description.isEmpty {
                        Text(blockingManager.blockingLevel.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Blocking Intensity")
                } footer: {
                    Text("Choose how strict you want the blocking to be during focus sessions.")
                }
                
                // App & Category Selection
                Section {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Selected Apps & Categories")
                                .font(.headline)
                            Text("\(blockingManager.blockedApps.count) apps, \(blockingManager.blockedCategories.count) categories")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Button("Choose Apps") {
                            showingFamilyActivityPicker = true
                        }
                        .buttonStyle(.bordered)
                    }
                } header: {
                    Text("Apps & Categories")
                } footer: {
                    Text("Select specific apps and app categories to block during focus sessions.")
                }
                
                // Advanced Features Section
//                Section {
//                    Toggle("Network-Level Blocking", isOn: $blockingManager.networkBlockingEnabled)
//                        .onChange(of: blockingManager.networkBlockingEnabled) { enabled in
//                            if enabled {
//                                networkService.blockDistractingSites()
//                            } else {
//                                networkService.unblockSites()
//                            }
//                        }
//                    
//                    Toggle("Focus Filter Integration", isOn: $blockingManager.focusFilterEnabled)
//                } header: {
//                    Text("Advanced Features")
//                } footer: {
//                    Text("Network-level blocking prevents access to distracting websites. Focus Filter integrates with iOS Focus modes.")
//                }
                
                // Network Blocking Details
                if blockingManager.networkBlockingEnabled {
                    Section {
                        NavigationLink("Blocked Websites") {
                            NetworkBlockingDetailView()
                                .environmentObject(networkService)
                        }
                        
                        if !networkService.blockedAttempts.isEmpty {
                            HStack {
                                Text("Recent Blocks")
                                Spacer()
                                Text("\(networkService.totalBlockedAttempts)")
                                    .foregroundColor(.secondary)
                            }
                        }
                    } header: {
                        Text("Network Blocking")
                    }
                }
                
                // Statistics Section
                Section {
                    let stats = blockingManager.getBlockingStatistics()
                    
                    HStack {
                        Text("Apps Blocked")
                        Spacer()
                        Text("\(stats.appsBlocked)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Effectiveness")
                        Spacer()
                        Text("\(Int(stats.blockingEffectiveness * 100))%")
                            .foregroundColor(.green)
                    }
                    
                    if let mostBlocked = stats.mostBlockedApp {
                        HStack {
                            Text("Most Blocked App")
                            Spacer()
                            Text(mostBlocked)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Statistics")
                }
                
                // Emergency Access Section
                Section {
                    Button("Request Emergency Access") {
                        let success = blockingManager.requestEmergencyAccess(reason: "User requested emergency access")
                        if success {
                            // Show success message
                        }
                    }
                    .foregroundColor(.orange)
                    .disabled(!blockingManager.isBlockingEnabled)
                } header: {
                    Text("Emergency Access")
                } footer: {
                    Text("Temporarily disable blocking for emergency situations (5 minutes).")
                }
        }
        .navigationTitle("App Blocking")
        .navigationBarTitleDisplayMode(.inline)
        .familyActivityPicker(
            isPresented: $showingFamilyActivityPicker,
            selection: $familyActivitySelection
        )
        .onChange(of: familyActivitySelection) { selection in
            blockingManager.updateFamilyActivitySelection(selection)
        }
        .onAppear {
            loadCurrentSelection()
            blockingManager.refreshAuthorizationStatus()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            blockingManager.refreshAuthorizationStatus()
        }
    }
    
    private func requestScreenTimeAuth() {
        Task {
            let success = await blockingManager.requestScreenTimeAuthorization()
            if success {
                showingScreenTimeAuth = false
            }
        }
    }
    
    private func loadCurrentSelection() {
        // Note: In iOS 15+, FamilyActivitySelection properties are read-only
        // The selection will be updated through the FamilyActivityPicker UI interaction
        // We cannot pre-populate the picker with existing selections programmatically
        // Users will need to re-select their apps/categories through the picker interface
    }
}

struct NetworkBlockingDetailView: View {
    @EnvironmentObject var networkService: NetworkBlockingService
    @State private var newDomain = ""
    
    var body: some View {
        List {
            Section {
                HStack {
                    TextField("Enter domain to block", text: $newDomain)
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    Button("Add") {
                        if !newDomain.isEmpty {
                            networkService.addBlockedDomain(newDomain)
                            newDomain = ""
                        }
                    }
                    .disabled(newDomain.isEmpty)
                }
            } header: {
                Text("Add Domain")
            }
            
            Section {
                ForEach(Array(networkService.blockedDomains), id: \.self) { domain in
                    HStack {
                        Text(domain)
                        Spacer()
                        Button("Remove") {
                            networkService.removeBlockedDomain(domain)
                        }
                        .foregroundColor(.red)
                    }
                }
            } header: {
                Text("Blocked Domains")
            }
            
            if !networkService.blockedAttempts.isEmpty {
                Section {
                    ForEach(networkService.blockedAttempts.suffix(20), id: \.timestamp) { attempt in
                        VStack(alignment: .leading) {
                            Text(attempt.domain)
                                .font(.headline)
                            Text(attempt.timestamp.formatted(.dateTime.hour().minute()))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Button("Clear History") {
                        networkService.clearBlockedAttempts()
                    }
                    .foregroundColor(.red)
                } header: {
                    Text("Recent Blocked Attempts")
                }
            }
        }
        .navigationTitle("Network Blocking")
        .navigationBarTitleDisplayMode(.inline)
    }
}

@available(iOS 15.0, *)
struct AppBlockingSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        AppBlockingSettingsView()
            .environmentObject(AppBlockingManager())
    }
}
