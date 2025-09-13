import Foundation
import Network

class NetworkBlockingService: ObservableObject {
    @Published var isBlocking = false
    @Published var blockedDomains: Set<String> = []
    @Published var blockedAttempts: [BlockedNetworkAttempt] = []
    
    private var monitor: NWPathMonitor?
    private let queue = DispatchQueue(label: "NetworkBlockingQueue")
    
    // Common distracting domains to block
    private let defaultBlockedDomains: Set<String> = [
        "facebook.com", "www.facebook.com",
        "instagram.com", "www.instagram.com",
        "twitter.com", "www.twitter.com",
        "tiktok.com", "www.tiktok.com",
        "youtube.com", "www.youtube.com",
        "reddit.com", "www.reddit.com",
        "snapchat.com", "www.snapchat.com",
        "discord.com", "www.discord.com",
        "twitch.tv", "www.twitch.tv",
        "netflix.com", "www.netflix.com",
        "pinterest.com", "www.pinterest.com"
    ]
    
    init() {
        loadBlockedDomains()
    }
    
    func blockDistractingSites(_ customDomains: [String] = []) {
        let domainsToBlock = customDomains.isEmpty ? Array(defaultBlockedDomains) : customDomains
        blockedDomains = Set(domainsToBlock)
        
        startNetworkMonitoring()
        isBlocking = true
        
        print("Network blocking started for domains: \(domainsToBlock)")
        
        // Save blocked domains
        saveBlockedDomains()
    }
    
    func unblockSites() {
        stopNetworkMonitoring()
        blockedDomains.removeAll()
        isBlocking = false
        
        print("Network blocking stopped")
    }
    
    func addBlockedDomain(_ domain: String) {
        blockedDomains.insert(domain)
        saveBlockedDomains()
    }
    
    func removeBlockedDomain(_ domain: String) {
        blockedDomains.remove(domain)
        saveBlockedDomains()
    }
    
    private func startNetworkMonitoring() {
        monitor = NWPathMonitor()
        
        monitor?.pathUpdateHandler = { [weak self] path in
            // Monitor network path changes
            // This is a simplified approach - actual blocking would require
            // a Network Extension or DNS filtering service
            DispatchQueue.main.async {
                self?.handleNetworkPathUpdate(path)
            }
        }
        
        monitor?.start(queue: queue)
    }
    
    private func stopNetworkMonitoring() {
        monitor?.cancel()
        monitor = nil
    }
    
    private func handleNetworkPathUpdate(_ path: NWPath) {
        // In a full implementation, this would intercept network requests
        // and block requests to domains in blockedDomains
        
        // For now, we'll simulate blocking by logging attempts
        if isBlocking && !blockedDomains.isEmpty {
            // Simulate a blocked attempt (in practice, this would come from actual network interception)
            simulateBlockedAttempt()
        }
    }
    
    private func simulateBlockedAttempt() {
        // This simulates detecting a blocked network attempt
        // In a real implementation, this would come from network interception
        let randomDomain = blockedDomains.randomElement() ?? "unknown.com"
        let attempt = BlockedNetworkAttempt(
            domain: randomDomain,
            timestamp: Date(),
            appName: "Unknown App"
        )
        
        blockedAttempts.append(attempt)
        
        // Keep only recent attempts (last 100)
        if blockedAttempts.count > 100 {
            blockedAttempts.removeFirst(blockedAttempts.count - 100)
        }
        
        print("Simulated blocked network attempt to: \(randomDomain)")
    }
    
    func isDomainBlocked(_ domain: String) -> Bool {
        return blockedDomains.contains(domain) || 
               blockedDomains.contains("www.\(domain)") ||
               blockedDomains.contains(domain.replacingOccurrences(of: "www.", with: ""))
    }
    
    private func loadBlockedDomains() {
        if let data = UserDefaults.standard.data(forKey: "blockedDomains"),
           let domains = try? JSONDecoder().decode(Set<String>.self, from: data) {
            blockedDomains = domains
        }
    }
    
    private func saveBlockedDomains() {
        if let data = try? JSONEncoder().encode(blockedDomains) {
            UserDefaults.standard.set(data, forKey: "blockedDomains")
        }
    }
    
    // MARK: - Statistics
    
    var totalBlockedAttempts: Int {
        blockedAttempts.count
    }
    
    var mostBlockedDomain: String? {
        let domainCounts = Dictionary(grouping: blockedAttempts) { $0.domain }
            .mapValues { $0.count }
        return domainCounts.max(by: { $0.value < $1.value })?.key
    }
    
    func getBlockedAttempts(for domain: String) -> [BlockedNetworkAttempt] {
        return blockedAttempts.filter { $0.domain == domain }
    }
    
    func clearBlockedAttempts() {
        blockedAttempts.removeAll()
    }
}

// MARK: - DNS-based Blocking (Advanced)

extension NetworkBlockingService {
    
    func setupDNSFiltering() {
        // This would implement DNS-based blocking
        // Requires Network Extension capability and more complex setup
        // For now, this is a placeholder for future implementation
        print("DNS filtering setup (placeholder)")
    }
    
    func configureDNSServer(_ dnsServer: String = "1.1.1.1") {
        // Configure DNS server for filtering
        // This would be implemented with Network Extension
        print("DNS server configuration (placeholder): \(dnsServer)")
    }
    
    private func blockDomainViaDNS(_ domain: String) {
        // Implementation would redirect blocked domains to localhost
        // or a blocked page via DNS manipulation
        print("DNS blocking for domain: \(domain)")
    }
} 