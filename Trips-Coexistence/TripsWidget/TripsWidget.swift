/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The types that provide timeline entries for the widget.
*/

import WidgetKit
import SwiftUI
import SwiftData

struct PersistenceController {
    let appGroupContainerID = "group.com.example.apple-samplecode.SampleTrips"
    
    static let shared = PersistenceController()

    let url: URL
    init() {
        guard let appGroupContainer = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupContainerID) else {
            fatalError("Shared file container could not be created.")
        }
        url = appGroupContainer.appendingPathComponent("Trips.sqlite")
    }
}

struct TripsWidget: Widget {
    let kind: String = "TripsWidget"
    let container: ModelContainer
    
    init() {
        container = try! ModelContainer(for: Trip.self, ModelConfiguration(url: PersistenceController.shared.url))
    }
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            TripsWidgetEntryView()
                .modelContainer(container)
        }
        .configurationDisplayName("Future Trips")
        .description("See your upcoming trips.")
    }
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        return SimpleEntry.placeholderEntry
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        completion(SimpleEntry.placeholderEntry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        var entries: [SimpleEntry] = []
        
        _ = PersistenceController.shared
        
        entries.append(SimpleEntry.placeholderEntry)
        
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    
    let startDate: Date
    let endDate: Date
    let name: String
    let destination: String
    
    static var placeholderEntry: SimpleEntry {
        let now = Date()
        let sevenDaysAfter = Calendar.current.date(byAdding: .day, value: 7, to: now)
        return SimpleEntry(date: now, startDate: now, endDate: sevenDaysAfter ?? Date(), name: "Honeymoon", destination: "Hawaii")
    }
}

struct TripsWidgetEntryView: View {
    @Query(sort: \.startDate, order: .forward)
    var trips: [Trip]
    
    var body: some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading) {
                HStack {
                    Image(systemName: "car.circle")
                        .imageScale(.large)
                    if let trip {
                        Text(trip.name)
                            .font(.system(.title2).weight(.semibold))
                            .minimumScaleFactor(0.5)
                    } else {
                        Text("No Trips!")
                    }
                    Spacer()
                }
                .foregroundColor(.green)
                
                Divider()
                if let trip {
                    Text(trip.destination)
                        .font(.system(.title3).weight(.semibold))
                        .minimumScaleFactor(0.5)
                    
                    let startDate = trip.startDate
                    Text(startDate, style: .date)
                        .foregroundColor(.gray)
                    
                    let endDate = trip.endDate
                    Text(endDate, style: .date)
                        .foregroundColor(.gray)
                }
            }
        }
    }
    
    var trip: Trip? {
        return trips.first(where: { $0.endDate > Date.now })
    }
}

@MainActor #Preview {
    TripsWidgetEntryView()
        .modelContainer(PreviewSampleData.container)
}
