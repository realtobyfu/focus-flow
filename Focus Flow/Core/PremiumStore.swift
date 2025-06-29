import SwiftUI
import StoreKit
import Combine

@MainActor
class PremiumStore: ObservableObject {
    @Published var products: [Product] = []
    @Published var purchasedProductIDs: Set<String> = []
    @Published var isLoading = false
    @Published var error: StoreError?
    @Published var showingPurchaseSheet = false
    @Published var currentSubscription: Product?
    
    private var updateListenerTask: Task<Void, Error>?
    private let productIDs: Set<String> = [
        "com.flowstate.app.monthly",
        "com.flowstate.app.yearly", 
        "com.flowstate.app.lifetime"
    ]
    
    var isPremium: Bool {
        return !purchasedProductIDs.isEmpty
    }
    
    var hasLifetime: Bool {
        return purchasedProductIDs.contains("com.flowstate.app.lifetime")
    }
    
    var hasActiveSubscription: Bool {
        return purchasedProductIDs.contains("com.flowstate.app.monthly") ||
               purchasedProductIDs.contains("com.flowstate.app.yearly")
    }
    
    init() {
        // Start listening for transaction updates
        updateListenerTask = listenForTransactions()
        
        Task {
            await requestProducts()
            await updatePurchasedProducts()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // MARK: - Product Loading
    
    func requestProducts() async {
        isLoading = true
        error = nil
        
        do {
            let storeProducts = try await Product.products(for: productIDs)
            
            await MainActor.run {
                self.products = storeProducts.sorted { product1, product2 in
                    // Sort by price: monthly, yearly, lifetime
                    if product1.id.contains("monthly") { return true }
                    if product2.id.contains("monthly") { return false }
                    if product1.id.contains("yearly") { return true }
                    if product2.id.contains("yearly") { return false }
                    return false
                }
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = StoreError.productRequestFailed
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Purchase Management
    
    func purchase(_ product: Product) async -> Bool {
        isLoading = true
        error = nil
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    // Transaction is verified, grant access
                    await updatePurchasedProducts()
                    await transaction.finish()
                    
                    await MainActor.run {
                        self.isLoading = false
                        HapticStyle.success.trigger()
                    }
                    return true
                    
                case .unverified:
                    // Transaction failed verification
                    await MainActor.run {
                        self.error = StoreError.verificationFailed
                        self.isLoading = false
                    }
                    return false
                }
                
            case .userCancelled:
                await MainActor.run {
                    self.isLoading = false
                }
                return false
                
            case .pending:
                await MainActor.run {
                    self.error = StoreError.purchasePending
                    self.isLoading = false
                }
                return false
                
            @unknown default:
                await MainActor.run {
                    self.error = StoreError.unknownError
                    self.isLoading = false
                }
                return false
            }
        } catch {
            await MainActor.run {
                self.error = StoreError.purchaseFailed
                self.isLoading = false
            }
            return false
        }
    }
    
    func restorePurchases() async {
        isLoading = true
        
        do {
            try await AppStore.sync()
            await updatePurchasedProducts()
            
            await MainActor.run {
                self.isLoading = false
                HapticStyle.success.trigger()
            }
        } catch {
            await MainActor.run {
                self.error = StoreError.restoreFailed
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Subscription Management
    
    func checkSubscriptionStatus() async {
        await updatePurchasedProducts()
        
        // Find current subscription
        for product in products {
            if purchasedProductIDs.contains(product.id) && product.type == .autoRenewable {
                currentSubscription = product
                break
            }
        }
    }
    
    func cancelSubscription() {
        // Direct user to subscription management in Settings
        if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
            UIApplication.shared.open(url)
        }
    }
    
    // MARK: - Transaction Handling
    
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)
                    await self.updatePurchasedProducts()
                    await transaction.finish()
                } catch {
                    // Handle verification failure
                    print("Transaction verification failed: \(error)")
                }
            }
        }
    }
    
    private func updatePurchasedProducts() async {
        var purchasedIDs: Set<String> = []
        
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                purchasedIDs.insert(transaction.productID)
            } catch {
                // Handle verification failure
                print("Transaction verification failed: \(error)")
            }
        }
        
        await MainActor.run {
            self.purchasedProductIDs = purchasedIDs
        }
    }
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.verificationFailed
        case .verified(let safe):
            return safe
        }
    }
    
    // MARK: - Feature Access Control
    
    func hasAccess(to feature: PremiumFeature) -> Bool {
        return isPremium || feature.isFreeFeature
    }
    
    func requiresPremium(_ feature: PremiumFeature) -> Bool {
        return !feature.isFreeFeature && !isPremium
    }
    
    // MARK: - Promotional Offers
    
    func getPromoOffer(for product: Product) -> Product.SubscriptionOffer? {
        // Return promotional offers if available
        return product.subscription?.promotionalOffers.first
    }
    
    func applyPromoCode(_ code: String) async -> Bool {
        // Handle promotional code redemption
        do {
            // Note: Code redemption sheet presentation may require different API
            // For now, return false as not implemented
            return false
        } catch {
            await MainActor.run {
                self.error = StoreError.promoCodeFailed
            }
            return false
        }
    }
}

// MARK: - Supporting Types

enum StoreError: LocalizedError, Identifiable {
    case productRequestFailed
    case purchaseFailed
    case verificationFailed
    case restoreFailed
    case purchasePending
    case promoCodeFailed
    case unknownError
    
    var id: String {
        switch self {
        case .productRequestFailed: return "product_request_failed"
        case .purchaseFailed: return "purchase_failed"
        case .verificationFailed: return "verification_failed"
        case .restoreFailed: return "restore_failed"
        case .purchasePending: return "purchase_pending"
        case .promoCodeFailed: return "promo_code_failed"
        case .unknownError: return "unknown_error"
        }
    }
    
    var errorDescription: String? {
        switch self {
        case .productRequestFailed:
            return "Failed to load products from the App Store"
        case .purchaseFailed:
            return "Purchase failed. Please try again"
        case .verificationFailed:
            return "Could not verify purchase"
        case .restoreFailed:
            return "Failed to restore purchases"
        case .purchasePending:
            return "Purchase is pending approval"
        case .promoCodeFailed:
            return "Failed to apply promotional code"
        case .unknownError:
            return "An unknown error occurred"
        }
    }
}

enum PremiumFeature: String, CaseIterable {
    case premiumThemes = "Premium Environmental Themes"
    case premiumSounds = "Premium Ambient Sounds"
    case advancedBlocking = "Advanced App Blocking"
    case detailedStatistics = "Detailed Analytics"
    case aiInsights = "AI Productivity Insights"
    case customGarden = "Custom Garden Plants"
    case unlimitedSessions = "Unlimited Focus Sessions"
    case exportData = "Export Statistics"
    case cloudSync = "Cloud Synchronization"
    case widgets = "Premium Widgets"
    
    var isFreeFeature: Bool {
        switch self {
        case .unlimitedSessions:
            return true // Free users get limited sessions
        default:
            return false
        }
    }
    
    var description: String {
        switch self {
        case .premiumThemes:
            return "Access to cosmic, aurora, and other premium environmental themes"
        case .premiumSounds:
            return "Unlock premium ambient sounds and create custom sound mixes"
        case .advancedBlocking:
            return "Multi-layer app blocking with Screen Time integration"
        case .detailedStatistics:
            return "Comprehensive analytics and productivity insights"
        case .aiInsights:
            return "AI-powered recommendations and pattern analysis"
        case .customGarden:
            return "Plant and grow premium garden varieties"
        case .unlimitedSessions:
            return "No limits on focus session duration or quantity"
        case .exportData:
            return "Export your statistics and progress data"
        case .cloudSync:
            return "Sync your data across all your devices"
        case .widgets:
            return "Premium widgets for your home screen"
        }
    }
    
    var icon: String {
        switch self {
        case .premiumThemes: return "paintbrush.fill"
        case .premiumSounds: return "speaker.wave.3.fill"
        case .advancedBlocking: return "shield.fill"
        case .detailedStatistics: return "chart.bar.fill"
        case .aiInsights: return "brain.head.profile"
        case .customGarden: return "leaf.fill"
        case .unlimitedSessions: return "infinity"
        case .exportData: return "square.and.arrow.up"
        case .cloudSync: return "icloud.fill"
        case .widgets: return "rectangle.3.offgrid.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .premiumThemes: return .purple
        case .premiumSounds: return .orange
        case .advancedBlocking: return .red
        case .detailedStatistics: return .blue
        case .aiInsights: return .green
        case .customGarden: return .mint
        case .unlimitedSessions: return .indigo
        case .exportData: return .teal
        case .cloudSync: return .cyan
        case .widgets: return .pink
        }
    }
}

// MARK: - Premium Feature Views

struct PremiumFeatureCard: View {
    let feature: PremiumFeature
    let isUnlocked: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: feature.icon)
                .font(.title2)
                .foregroundColor(feature.color)
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(feature.rawValue)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(feature.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
            
            if isUnlocked {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.green)
            } else {
                Image(systemName: "lock.fill")
                    .font(.title2)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isUnlocked ? feature.color.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
}

struct PremiumPlanCard: View {
    let product: Product
    let isPopular: Bool
    let onPurchase: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            if isPopular {
                Text("MOST POPULAR")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.orange))
            }
            
            VStack(spacing: 8) {
                Text(planTitle)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(product.displayPrice)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                if let period = billingPeriod {
                    Text(period)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                if let savings = savingsText {
                    Text(savings)
                        .font(.caption)
                        .foregroundColor(.green)
                        .fontWeight(.medium)
                }
            }
            
            Button(action: onPurchase) {
                Text("Get Premium")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isPopular ? Color.orange : Color.blue)
                    )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isPopular ? Color.orange : Color.clear, lineWidth: 2)
        )
    }
    
    private var planTitle: String {
        if product.id.contains("monthly") {
            return "Monthly"
        } else if product.id.contains("yearly") {
            return "Yearly"
        } else {
            return "Lifetime"
        }
    }
    
    private var billingPeriod: String? {
        if product.id.contains("monthly") {
            return "per month"
        } else if product.id.contains("yearly") {
            return "per year"
        }
        return nil
    }
    
    private var savingsText: String? {
        if product.id.contains("yearly") {
            return "Save 40% vs monthly"
        } else if product.id.contains("lifetime") {
            return "Best value"
        }
        return nil
    }
}

// MARK: - Premium Paywall View

struct PremiumPaywallView: View {
    @StateObject private var store = PremiumStore()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.yellow)
                        
                        Text("Unlock Premium")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Get the most out of your focus sessions with premium features")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal)
                    
                    // Features
                    LazyVStack(spacing: 12) {
                        ForEach(PremiumFeature.allCases, id: \.rawValue) { feature in
                            PremiumFeatureCard(
                                feature: feature,
                                isUnlocked: store.hasAccess(to: feature)
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    // Pricing Plans
                    if !store.products.isEmpty {
                        VStack(spacing: 16) {
                            Text("Choose Your Plan")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            LazyVStack(spacing: 12) {
                                ForEach(store.products, id: \.id) { product in
                                    PremiumPlanCard(
                                        product: product,
                                        isPopular: product.id.contains("yearly")
                                    ) {
                                        Task {
                                            await store.purchase(product)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Restore Purchases
                    Button("Restore Purchases") {
                        Task {
                            await store.restorePurchases()
                        }
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                    
                    // Legal
                    HStack(spacing: 20) {
                        Button("Terms of Service") {
                            // Open terms
                        }
                        
                        Button("Privacy Policy") {
                            // Open privacy policy
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .padding(.vertical)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .overlay {
                if store.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.3))
                }
            }
        }
        .alert(item: $store.error) { error in
            Alert(
                title: Text("Error"),
                message: Text(error.errorDescription ?? "Unknown error"),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}
