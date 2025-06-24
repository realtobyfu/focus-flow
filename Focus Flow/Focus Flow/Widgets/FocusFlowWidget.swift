#if canImport(WidgetKit) && os(iOS)
import WidgetKit
import SwiftUI

// MARK: - Widget Entry and Provider
struct SimpleEntry: TimelineEntry {
    let date: Date
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        completion(SimpleEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        let entries = [SimpleEntry(date: Date())]
        completion(Timeline(entries: entries, policy: .never))
    }
}

// MARK: - Widget View
struct FocusFlowWidgetEntryView: View {
    var entry: SimpleEntry

    var body: some View {
        VStack {
            Text("Focus Flow")
                .font(.headline)
            Text(entry.date, style: .time)
                .font(.title)
        }
        .padding()
        .premiumGlassEffect()
    }
}

// MARK: - Widget Definition
struct FocusFlowWidget: Widget {
    let kind: String = "FocusFlowWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            FocusFlowWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Focus Flow")
        .description("Quick access to focus sessions")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
#endif 