//
//  AppBlockingSettingsView.swift
//  Focus Flow
//
//  Created by Tobias Fu on 4/25/25.
//

import SwiftUI

struct AppBlockingSettingsView: View {
    @ObservedObject var blockingManager: AppBlockingManager
    @State private var showingAddAppAlert = false
    @State private var newAppName = ""
    @State private var newAppBundleID = ""
    
    var body: some View {
        List {
            Section(header: Text("App Blocking")) {
                Toggle("Enable App Blocking During Focus", isOn: Binding(
                    get: { blockingManager.isBlockingEnabled },
                    set: { _ in blockingManager.toggleBlockingEnabled() }
                ))
                .toggleStyle(SwitchToggleStyle(tint: Color.themePrimary))
                
                if blockingManager.isBlockingEnabled {
                    Text("Apps will be restricted during focus sessions")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
            }
            
            if blockingManager.isBlockingEnabled {
                Section(header:
                    HStack {
                        Text("Manage Blocked Apps")
                        Spacer()
                        Button(action: {
                            showingAddAppAlert = true
                        }) {
                            Image(systemName: "plus")
                                .foregroundColor(Color.themePrimary)
                        }
                    }
                ) {
                    if blockingManager.blockedApps.isEmpty {
                        Text("No apps configured")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(blockingManager.blockedApps) { app in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(app.name)
                                        .font(.headline)
                                    Text(app.bundleId)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Toggle("", isOn: Binding(
                                    get: { app.isBlocked },
                                    set: { _ in blockingManager.toggleBlock(for: app) }
                                ))
                                .toggleStyle(SwitchToggleStyle(tint: Color.themePrimary))
                            }
                        }
                        .onDelete(perform: blockingManager.removeApp)
                    }
                }
                
                Section(header: Text("Currently Blocked")) {
                    if blockingManager.currentlyBlockedApps.isEmpty {
                        Text("No apps being blocked")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(blockingManager.currentlyBlockedApps) { app in
                                    HStack {
                                        Image(systemName: "app.fill")
                                            .foregroundColor(.white)
                                            .padding(6)
                                            .background(Color.themePrimary)
                                            .clipShape(RoundedRectangle(cornerRadius: 6))
                                        
                                        Text(app.name)
                                            .font(.caption)
                                            .bold()
                                    }
                                    .padding(.vertical, 4)
                                    .padding(.horizontal, 8)
                                    .background(Color.gray.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                            .padding(.vertical, 6)
                        }
                    }
                }
                
                Section(header: Text("About App Blocking")) {
                    Text("App blocking helps you stay focused by preventing distracting apps during focus sessions. Focus Flow will attempt to block access to selected apps when a timer is running.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("App Blocking")
        .alert("Add New App", isPresented: $showingAddAppAlert) {
            TextField("App Name", text: $newAppName)
            TextField("Bundle ID", text: $newAppBundleID)
            
            Button("Cancel", role: .cancel) {
                newAppName = ""
                newAppBundleID = ""
            }
            
            Button("Add") {
                if !newAppName.isEmpty && !newAppBundleID.isEmpty {
                    blockingManager.addApp(name: newAppName, bundleId: newAppBundleID)
                    newAppName = ""
                    newAppBundleID = ""
                }
            }
        } message: {
            Text("Enter the details of the app you want to block during focus sessions.")
        }
    }
}

// Preview
struct AppBlockingSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AppBlockingSettingsView(blockingManager: AppBlockingManager())
        }
    }
}
