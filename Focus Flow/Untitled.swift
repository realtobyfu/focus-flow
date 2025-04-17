//
//  PublicNoteDetailView.swift
//  Ecrivez-local
//
//  Created by Tobias Fu on 2/5/25.
//  Redesigned with improved UI and comment functionality
//

import SwiftUI
import CoreLocation

struct PublicNoteDetailView: View {
    let note: SupabaseNote
    let isAuthenticated: Bool
    let currentUserID: UUID?
    
    @State private var locationString: String = ""

    // MARK: - State Variables
    @State private var hasLiked = false
    @State private var likeCount = 0
    @State private var animateLike = false
    @State private var commentText = ""
    @State private var showingComments = false
    
    // Sample comments for UI preview
    @State private var comments: [CommentPreview] = []
    
    struct CommentPreview: Identifiable {
        let id = UUID()
        let username: String
        let text: String
        let timestamp: Date
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // MARK: - Combined Header & Content
                VStack(alignment: .leading, spacing: 16) {
                    // Header
                    noteHeader
                    
                    // Note content
                    Text(note.content)
                        .font(.body)
                        .padding(.horizontal)
                    
                    // MARK: - Metadata
                    HStack(spacing: 16) {
                        
                        Spacer()

                        // Date
                        if let date = note.date {
                            HStack(spacing: 4) {
                                Image(systemName: "calendar")
                                    .font(.caption)
                                Text(formatDate(date))
                                    .font(.caption)
                            }
                        }
                        
                        // Location
                        if !locationString.isEmpty {
                            HStack(spacing: 4) {
                                Image(systemName: "mappin")
                                    .font(.caption)
                                Text(locationString)
                                    .font(.caption)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.1), radius: 5)
                .padding()
                
                // MARK: - Actions Bar
                actionsBar
                    .padding(.horizontal)
                
                // MARK: - Comments Section
                if showingComments {
                    commentsSection
                        .padding()
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            reverseGeocodeIfNeeded()
            Task {
                await loadLikeState()
                loadSampleComments() // In real app, fetch from database
            }
        }
    }
    
    // MARK: - Note Header
    private var noteHeader: some View {
        HStack(spacing: 16) {
            // Category Icon

            Spacer()

            
            VStack(alignment: .leading, spacing: 50) {
                // Author info
                
                if note.isAnnonymous == true {
                    Text("anonymous")
                        .font(.headline)
                        .foregroundColor(.black)
                } else if let userName = note.profiles?.username {
                    HStack(spacing: 0) {
                        Text("@")
                            .font(.headline)
                        Text("\(userName)")
                            .font(.custom("Baskerville", size: 25))
                            .italic()
                    }
                } else {
                    // Fallback if both conditions fail
                    Text("User")
                        .font(.custom("Baskerville", size: 25))
                        .italic()
                }
            }
            .foregroundColor(.black)

            ZStack {
                Circle()
                    .fill(backgroundColor)
                    .frame(width: 50, height: 50)
                
                Image(systemName: note.symbol)
                    .font(.title2)
                    .foregroundColor(.white)
            }

        }
        .padding(.bottom, 0)
    }
    
    // MARK: - Actions Bar
    private var actionsBar: some View {
        HStack(spacing: 60) {
            // Like Button with counter
            VStack(spacing: 4) {
                Button(action: toggleLike) {
                    Image(systemName: hasLiked ? "heart.fill" : "heart")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                        .foregroundColor(hasLiked ? .red : .gray)
                        .scaleEffect(animateLike ? 1.2 : 1.0)
                }
                .buttonStyle(StaticButtonStyle())
                
                if likeCount > 0 {
                    Text("\(likeCount)")
                        .font(.caption)
                        .foregroundColor(hasLiked ? .red : .gray)
                }
            }
            .frame(height: 50) // Fixed height to prevent movement
            
            // Comment Button with counter
            VStack(spacing: 4) {
                Button {
                    withAnimation {
                        showingComments.toggle()
                    }
                } label: {
                    Image(systemName: showingComments ? "bubble.left.fill" : "bubble.left")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                        .foregroundColor(showingComments ? .blue : .gray)
                }
                .buttonStyle(StaticButtonStyle())
                
                if comments.count > 0 {
                    Text("\(comments.count)")
                        .font(.caption)
                        .foregroundColor(showingComments ? .blue : .gray)
                }
            }
            .frame(height: 50) // Fixed height to prevent movement
            
            Spacer()
        }
        .padding(.horizontal, 30)
        .padding(.vertical, 12)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5)
    }
    
    // Custom button style to prevent movement when pressed
    struct StaticButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                // No transformations when pressed
        }
    }
    
    // MARK: - Comments Section
    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Comments")
                .font(.headline)
            
            // New Comment Entry
            if isAuthenticated {
                HStack {
                    TextField("Add a comment...", text: $commentText)
                        .textFieldStyle(.roundedBorder)
                    
                    Button {
                        if !commentText.isEmpty {
                            // In a real app, you would save the comment
                            print("Post comment: \(commentText)")
                            commentText = ""
                        }
                    } label: {
                        Text("Post")
                    }
                    .buttonStyle(.bordered)
                    .disabled(commentText.isEmpty)
                }
            }
            
            // Comments List
            if comments.isEmpty {
                Text("No comments yet")
                    .italic()
                    .foregroundColor(.secondary)
                    .padding(.top)
            } else {
                ForEach(comments) { comment in
                    CommentView(comment: comment)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 5)
    }
    
    // MARK: - Comment View
    struct CommentView: View {
        let comment: CommentPreview
        
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 0) {
                            Text("@")
                                .font(.subheadline)

                            Text("\(comment.username)")
                                .font(.custom("Baskerville", size: 18))
                                .italic()
                        }

                        // Simplified timestamp format
                        Text(formattedTimestamp(for: comment.timestamp))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Text(comment.text)
                    .font(.body)
                
                Divider()
            }
            .padding(.vertical, 4)
        }
        
        // Helper to format timestamp as requested
        private func formattedTimestamp(for date: Date) -> String {
            let now = Date()
            let components = Calendar.current.dateComponents([.minute, .hour, .day], from: date, to: now)
            
            // Show just one time indicator (minutes, hours, or days)
            if let minutes = components.minute, minutes < 60 {
                return "\(minutes) min\(minutes == 1 ? "" : "s") ago"
            } else if let hours = components.hour, hours < 24 {
                return "\(hours) hour\(hours == 1 ? "" : "s") ago"
            } else if let days = components.day, days == 1 {
                return "Yesterday"
            } else if let days = components.day, days < 7 {
                return "\(days) day\(days == 1 ? "" : "s") ago"
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM d"
                return formatter.string(from: date)
            }
        }
    }
    
    // MARK: - Helper Functions
    private func formatDate(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = "MMM d, yyyy"
        return df.string(from: date)
    }
    
    private func loadLikeState() async {
        // Mock data for UI preview
        hasLiked = true
        likeCount = 42
    }
    
    private func toggleLike() {
        hasLiked.toggle()
        likeCount += hasLiked ? 1 : -1
        
        animateLike = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.spring()) {
                animateLike = false
            }
        }
        
        Task {
            await updateDatabaseLike()
        }
    }
    
    private func updateDatabaseLike() async {
        // Database update logic would go here
    }
    
    private func loadSampleComments() {
        // Create some sample comments for preview
        comments = [
            CommentPreview(
                username: "sarah",
                text: "This is really insightful, thanks for sharing!",
                timestamp: Date().addingTimeInterval(-3600) // 1 hour ago
            ),
            CommentPreview(
                username: "alex",
                text: "I've been thinking about this topic lately. Great perspective.",
                timestamp: Date().addingTimeInterval(-86400) // 1 day ago
            ),
            CommentPreview(
                username: "jordan",
                text: "Have you considered looking at it from another angle? Would be interesting to discuss.",
                timestamp: Date().addingTimeInterval(-259200) // 3 days ago
            )
        ]
    }
    
    private func reverseGeocodeIfNeeded() {
        guard let lat = note.locationLatitude, let lon = note.locationLongitude else {
            locationString = ""
            return
        }
        let location = CLLocation(latitude: Double(lat)!, longitude: Double(lon)!)
        CLGeocoder().reverseGeocodeLocation(location) { placemarks, error in
            if let placemark = placemarks?.first, error == nil {
                let locality = placemark.locality ?? ""
                if !locality.isEmpty {
                    locationString = locality
                }
            }
        }
    }
    
    private var backgroundColor: Color {
        switch note.colorString {
            case "green":   return .green
            case "blue":    return .blue
            case "yellow":  return .yellow
            case "pink":    return .pink
            case "brown":   return .brown
            case "gray":    return .gray
            case "red":     return .red
            case "purple":  return .purple
            case "orange":  return .orange
            case "teal":    return .teal
            case "indigo":  return .indigo
            default:        return .black
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        PublicNoteDetailView(
            note: SupabaseNote(
                id: UUID(),
                owner_id: UUID(),
                category_id: UUID(),
                content: "This is a sample note with some interesting content that talks about various things. It could be a longer text with multiple paragraphs and ideas that the user has shared with the community.\n\nThe design now shows sample comments and improved button layout with counters.",
                rtf_content: nil,
                date: Date(),
                locationName: "San Francisco",
                locationLatitude: "37.7749",
                locationLongitude: "-122.4194",
                colorString: "blue",
                symbol: "book.fill",
                isAnnonymous: false
            ),
            isAuthenticated: true,
            currentUserID: UUID()
        )
    }
}

//
//  SupabaseNote.swift
//  Ecrivez-local
//
//  Created by Tobias Fu on 2/27/25.
//

import Foundation
import CoreLocation

struct SupabaseNote: Codable, Identifiable {
    let id: UUID
    let owner_id: UUID
    
    let category_id: UUID?
    let content: String
    var rtf_content: String?
    
    var date: Date?
    var locationName: String?
    var locationLongitude: String?
    var locationLatitude: String?
    
    var isAnnonymous: Bool?  // <-- This was already declared
    
    let colorString: String
    let symbol: String
    
    var profiles: ProfileData? = nil
    
    struct ProfileData: Codable {
        let username: String?
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, owner_id, category_id
        case content, rtf_content
        case date, locationLongitude, locationLatitude
        case isAnnonymous
        case colorString, symbol
        case profiles
    }
    
    // MARK: - Decoder for fetching from DB
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.owner_id = try container.decode(UUID.self, forKey: .owner_id)
        self.category_id = try container.decodeIfPresent(UUID.self, forKey: .category_id)
        
        self.content = try container.decode(String.self, forKey: .content)
        self.rtf_content = try container.decodeIfPresent(String.self, forKey: .rtf_content)
        
        if let dateString = try container.decodeIfPresent(String.self, forKey: .date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            self.date = formatter.date(from: dateString)
        } else {
            self.date = nil
        }
        
        self.locationLongitude = try container.decodeIfPresent(String.self, forKey: .locationLongitude)
        self.locationLatitude = try container.decodeIfPresent(String.self, forKey: .locationLatitude)
        self.isAnnonymous = try container.decodeIfPresent(Bool.self, forKey: .isAnnonymous)
        
        self.colorString = try container.decode(String.self, forKey: .colorString)
        self.symbol = try container.decode(String.self, forKey: .symbol)
        
        self.profiles = try container.decodeIfPresent(ProfileData.self, forKey: .profiles)
    }
    
    // MARK: - Convenience init for uploading to DB
    init(id: UUID,
         owner_id: UUID,
         category_id: UUID?,
         content: String,
         rtf_content: String?,
         date: Date?,
         locationName: String?,
         locationLatitude: String?,
         locationLongitude: String?,
         colorString: String,
         symbol: String,
         isAnnonymous: Bool?
    ) {
        self.id = id
        self.owner_id = owner_id
        self.category_id = category_id
        self.content = content
        self.rtf_content = rtf_content
        self.date = date
        self.locationName = locationName
        self.locationLongitude = locationLongitude
        self.locationLatitude = locationLatitude
        self.isAnnonymous = isAnnonymous
        
        self.colorString = colorString
        self.symbol = symbol
        
        self.profiles = nil
    }
}


extension SupabaseNote {
    var location: CLLocation? {
//        print(CLLocation(latitude: Double(locationLatitude), longitude: Double(locationLatitude)))
        guard
            let latString = locationLatitude,
            let lonString = locationLongitude,
            let lat = Double(latString),
            let lon = Double(lonString)
        else {
            print("cannot find the location")
            return nil
        }
        return CLLocation(latitude: lat, longitude: lon)
    }
}
