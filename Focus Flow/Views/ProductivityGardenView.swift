import SwiftUI

struct ProductivityGardenView: View {
    @EnvironmentObject var gardenManager: ProductivityGardenManager
    @State private var selectedPlant: GardenPlant?
    @State private var showingPlantStore = false
    @State private var animateWatering = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Garden Stats
                gardenStatsSection
                
                // Garden Grid
                gardenGridSection
                
                // Daily Care Actions
                dailyCareSection
                
                // Achievements
                achievementsSection
            }
            .padding()
        }
        .navigationTitle("Productivity Garden")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingPlantStore = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingPlantStore) {
            PlantStoreView()
                .environmentObject(gardenManager)
        }
        .sheet(item: $selectedPlant) { plant in
            PlantDetailView(plant: plant)
                .environmentObject(gardenManager)
        }
    }
    
    // MARK: - Garden Stats Section
    private var gardenStatsSection: some View {
        GlassCard {
            VStack(spacing: 20) {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Level \(gardenManager.garden.level) Garden")
                            .font(AppTheme.Typography.title2)
                            .foregroundColor(.primary)
                        
                        ProgressView(value: Double(gardenManager.garden.experience), total: Double(gardenManager.garden.experienceToNextLevel))
                            .tint(Color.green)
                            .scaleEffect(y: 2)
                    }
                    
                    Spacer()
                    
                    // Garden Health Indicator
                    ZStack {
                        Circle()
                            .fill(LinearGradient(
                                colors: [Color.green.opacity(0.3), Color.green.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 80, height: 80)
                        
                        VStack(spacing: 4) {
                            Image(systemName: "leaf.fill")
                                .font(.system(size: 28, weight: .medium))
                                .foregroundColor(.green)
                            
                            Text("100%")
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(.green)
                        }
                    }
                }
                
                HStack(spacing: 30) {
                    StatItem(
                        icon: "flame.fill",
                        value: "\(gardenManager.dailyProgress.currentStreak)",
                        label: "Day Streak",
                        color: .orange
                    )
                    
                    StatItem(
                        icon: "tree.fill",
                        value: "\(gardenManager.plants.count)",
                        label: "Plants",
                        color: .green
                    )
                    
                    StatItem(
                        icon: "sparkles",
                        value: "\(gardenManager.plants.filter { $0.canHarvest }.count)",
                        label: "Ready",
                        color: .purple
                    )
                }
            }
        }
    }
    
    // MARK: - Garden Grid Section
    private var gardenGridSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Plants")
                .font(AppTheme.Typography.headline)
            
            if !gardenManager.plants.isEmpty {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(gardenManager.plants) { plant in
                        PlantCard(plant: plant) {
                            selectedPlant = plant
                        }
                    }
                }
            } else {
                EmptyGardenView {
                    showingPlantStore = true
                }
            }
        }
    }
    
    // MARK: - Daily Care Section
    private var dailyCareSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Daily Care")
                .font(AppTheme.Typography.headline)
            
            HStack(spacing: 12) {
                CareActionButton(
                    icon: "drop.fill",
                    title: "Water All",
                    color: .blue,
                    isEnabled: !gardenManager.plants.isEmpty
                ) {
                    withAnimation(.spring()) {
                        animateWatering = true
                        // Water all plants functionality would go here
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        animateWatering = false
                    }
                }
                
                CareActionButton(
                    icon: "sun.max.fill",
                    title: "Sunlight",
                    color: .yellow,
                    isEnabled: true
                ) {
                    // Sunlight is automatic based on focus sessions
                }
            }
        }
    }
    
    // MARK: - Achievements Section
    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Achievements")
                    .font(AppTheme.Typography.headline)
                
                Spacer()
                
                Text("\(gardenManager.achievements.count) / \(Achievement.allAchievements.count)")
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(.secondary)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(Achievement.allAchievements, id: \.self) { achievement in
                        AchievementBadge(
                            achievement: achievement,
                            isUnlocked: gardenManager.achievements.contains(achievement)
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Plant Card
struct PlantCard: View {
    let plant: GardenPlant
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [Color.green.opacity(0.2), Color.green.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 80, height: 80)
                    
                    Text(plant.plantType.icon)
                        .font(.system(size: 40))
                    
                    // Growth indicator
                    Circle()
                        .trim(from: 0, to: plant.growth)
                        .stroke(Color.green, lineWidth: 3)
                        .frame(width: 75, height: 75)
                        .rotationEffect(.degrees(-90))
                }
                
                Text(plant.plantType.rawValue)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                // Status indicators
                HStack(spacing: 4) {
                    if plant.waterLevel < 50 {
                        Image(systemName: "drop")
                            .font(.system(size: 12))
                            .foregroundColor(.blue)
                    }
                    
                    if plant.canHarvest {
                        Image(systemName: "sparkles")
                            .font(.system(size: 12))
                            .foregroundColor(.yellow)
                    }
                }
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Empty Garden View
struct EmptyGardenView: View {
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "leaf.arrow.circlepath")
                .font(.system(size: 60, weight: .light))
                .foregroundColor(.green.opacity(0.5))
            
            Text("Start Your Garden")
                .font(AppTheme.Typography.headline)
                .foregroundColor(.primary)
            
            Text("Plant your first seed and watch it grow as you focus")
                .font(AppTheme.Typography.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            PrimaryButton(
                title: "Plant First Seed",
                icon: "plus",
                action: action
            )
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.l)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.l)
                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Care Action Button
struct CareActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let isEnabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(isEnabled ? color : .gray)
                
                Text(title)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(isEnabled ? .primary : .gray)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.m)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.m)
                            .stroke(isEnabled ? color.opacity(0.3) : Color.gray.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .disabled(!isEnabled)
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Achievement Badge
struct AchievementBadge: View {
    let achievement: Achievement
    let isUnlocked: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(isUnlocked ? 
                        LinearGradient(
                            colors: [Color.yellow, Color.orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) : 
                        LinearGradient(
                            colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                
                Image(systemName: achievement.icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(isUnlocked ? .white : .gray)
            }
            
            Text(achievement.name)
                .font(AppTheme.Typography.caption)
                .foregroundColor(isUnlocked ? .primary : .gray)
                .multilineTextAlignment(.center)
                .frame(width: 80)
        }
    }
}

// MARK: - Stat Item
struct StatItem: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(color)
            
            Text(value)
                .font(AppTheme.Typography.headline)
                .foregroundColor(.primary)
            
            Text(label)
                .font(AppTheme.Typography.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Plant Detail View
struct PlantDetailView: View {
    let plant: GardenPlant
    @EnvironmentObject var gardenManager: ProductivityGardenManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Plant Visual
                    ZStack {
                        Circle()
                            .fill(LinearGradient(
                                colors: [Color.green.opacity(0.3), Color.green.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 150, height: 150)
                        
                        Text(plant.plantType.icon)
                            .font(.system(size: 80))
                    }
                    .padding()
                    
                    // Plant Info
                    VStack(spacing: 16) {
                        Text(plant.plantType.rawValue)
                            .font(AppTheme.Typography.title1)
                        
                        Text("Stage: \(plant.growthStage.description)")
                            .font(AppTheme.Typography.body)
                            .foregroundColor(.secondary)
                    }
                    
                    // Plant Stats
                    GlassCard {
                        VStack(spacing: 20) {
                            PlantStatRow(
                                label: "Growth Progress",
                                value: "\(Int(plant.growth * 100))%",
                                progress: plant.growth,
                                color: .green
                            )
                            
                            PlantStatRow(
                                label: "Water Level",
                                value: plant.waterLevel < 50 ? "Needs Water" : "Hydrated",
                                progress: plant.waterLevel / 100,
                                color: .blue
                            )
                            
                            PlantStatRow(
                                label: "Total Care Time",
                                value: "\(plant.totalCareTime) min",
                                progress: nil,
                                color: .purple
                            )
                        }
                    }
                    
                    // Actions
                    if plant.waterLevel < 50 {
                        PrimaryButton(
                            title: "Water Plant",
                            icon: "drop.fill",
                            action: {
                                // Water plant functionality
                                dismiss()
                            }
                        )
                    }
                    
                    if plant.canHarvest {
                        PrimaryButton(
                            title: "Harvest",
                            icon: "sparkles",
                            action: {
                                gardenManager.harvestPlant(plant)
                                dismiss()
                            }
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("Plant Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Plant Stat Row
struct PlantStatRow: View {
    let label: String
    let value: String
    let progress: Double?
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label)
                    .font(AppTheme.Typography.body)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(value)
                    .font(AppTheme.Typography.body)
                    .foregroundColor(.primary)
            }
            
            if let progress = progress {
                ProgressView(value: progress)
                    .tint(color)
                    .scaleEffect(y: 2)
            }
        }
    }
}

// MARK: - Plant Store View
struct PlantStoreView: View {
    @EnvironmentObject var gardenManager: ProductivityGardenManager
    @Environment(\.dismiss) private var dismiss
    
    let availablePlants = [
        (name: "Sunflower", emoji: "🌻", cost: 0),
        (name: "Rose", emoji: "🌹", cost: 50),
        (name: "Tulip", emoji: "🌷", cost: 75),
        (name: "Cactus", emoji: "🌵", cost: 100),
        (name: "Bonsai", emoji: "🌳", cost: 150)
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(availablePlants, id: \.name) { plantInfo in
                        PlantStoreItem(
                            name: plantInfo.name,
                            emoji: plantInfo.emoji,
                            cost: plantInfo.cost,
                            canAfford: gardenManager.garden.seeds >= plantInfo.cost
                        ) {
                            // Find the next available slot
                            let nextSlot = gardenManager.plants.count
                            
                            // Map plant name to PlantType
                            let plantType: PlantType = {
                                switch plantInfo.name {
                                case "Sunflower": return .defaultPlant
                                case "Rose": return .focusTree
                                case "Tulip": return .creativeBush
                                case "Cactus": return .learningVine
                                case "Bonsai": return .mindfulLotus
                                default: return .defaultPlant
                                }
                            }()
                            
                            gardenManager.plantSeed(type: plantType, in: nextSlot)
                            dismiss()
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Plant Store")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Plant Store Item
struct PlantStoreItem: View {
    let name: String
    let emoji: String
    let cost: Int
    let canAfford: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Text(emoji)
                    .font(.system(size: 40))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(name)
                        .font(AppTheme.Typography.headline)
                        .foregroundColor(.primary)
                    
                    Text("\(cost) Seeds")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(canAfford ? .secondary : .red)
                }
                
                Spacer()
                
                if canAfford {
                    Text("Plant")
                        .font(AppTheme.Typography.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(Color.green))
                } else {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.m)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.m)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        .disabled(!canAfford)
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Achievement Extensions
extension Achievement {
    var name: String {
        return title
    }
}

#Preview {
    ProductivityGardenView()
        .environmentObject(ProductivityGardenManager())
}