import SwiftUI

struct TabBarButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                Text(title)
                    .font(.caption)
            }
            .foregroundColor(isSelected ? Color.themePrimary : Color.gray)
            .frame(maxWidth: .infinity)
        }
    }
}

struct TabBarButton_Previews: PreviewProvider {
    static var previews: some View {
        HStack {
            TabBarButton(
                title: "Focus",
                icon: "timer",
                isSelected: true,
                action: {}
            )
            
            TabBarButton(
                title: "Tasks",
                icon: "checklist",
                isSelected: false,
                action: {}
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
} 