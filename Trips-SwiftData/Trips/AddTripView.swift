/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A SwiftUI view that adds a new trip.
*/

import SwiftUI
import WidgetKit

struct AddTripView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.calendar) private var calendar
    @Environment(\.dismiss) private var dismiss
    @Environment(\.timeZone) private var timeZone
    @State private var name: String = ""
    @State private var destination: String = ""
    @State private var startDate = Date()
    @State private var endDate = Date()
    
    var dateRange: ClosedRange<Date> {
        let start = Date.now
        let components = DateComponents(calendar: calendar, timeZone: timeZone, year: 1)
        let end = calendar.date(byAdding: components, to: start)!
        return start ... end
    }
    
    var body: some View {
        TripForm {
            Section(header: Text("Trip Title")) {
                TripGroupBox {
                    TextField("Enter title here…", text: $name)
                }
            }
            
            Section(header: Text("Trip Destination")) {
                TripGroupBox {
                    TextField("Enter destination here…", text: $destination)
                }
            }
            
            Section(header: Text("Trip Dates")) {
                TripGroupBox {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Start Date:")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            DatePicker(selection: $startDate, in: dateRange,
                                       displayedComponents: .date) {
                                Label("Start Date", systemImage: "calendar")
                            }
                            .labelsHidden()
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("End Date:")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            DatePicker(selection: $endDate, in: dateRange,
                                       displayedComponents: .date) {
                                Label("End Date", systemImage: "calendar")
                            }
                            .labelsHidden()
                        }
                    }
                }
            }
        }
        .frame(idealWidth: LayoutConstants.sheetIdealWidth,
               idealHeight: LayoutConstants.sheetIdealHeight)
        .navigationTitle("Add Trip")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Dismiss") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button("Done") {
                    addTrip()
                    WidgetCenter.shared.reloadTimelines(ofKind: "TripsWidget")
                    dismiss()
                }
                .disabled(name.isEmpty || destination.isEmpty)
            }
        }
    }

    private func addTrip() {
        withAnimation {
            let newTrip = Trip(dittoId: UUID().uuidString, name: name, destination: destination, startDate: startDate, endDate: endDate)
            modelContext.insert(newTrip)
        }
    }
}

#Preview(traits: .sampleData) {
    AddTripView()
}
