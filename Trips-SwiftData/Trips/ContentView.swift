/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A SwiftUI view that shows the main UI.
*/

import SwiftUI
import SwiftData
import WidgetKit

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Trip.startDate, order: .forward)
    var trips: [Trip]
    
    @State private var showAddTrip = false
    @State private var selection: Trip?
    @State private var path: [Trip] = []
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                ForEach(trips) { trip in
                    TripListItem(trip: trip)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                deleteTrip(trip)
                                WidgetCenter.shared.reloadTimelines(ofKind: "TripsWidget")
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
                .onDelete(perform: deleteTrips(at:))
            }
            .overlay {
                if trips.isEmpty {
                    ContentUnavailableView {
                         Label("No Trips", systemImage: "car.circle")
                    } description: {
                         Text("New trips you create will appear here.")
                    }
                }
            }
            .navigationTitle("Upcoming Trips")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                        .disabled(trips.isEmpty)
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Spacer()
                    Button {
                        showAddTrip = true
                    } label: {
                        Label("Add trip", systemImage: "plus")
                    }
                }
            }
        } detail: {
            if let selection = selection {
                NavigationStack {
                    TripDetailView(trip: selection)
                }
            }
        }
        .sheet(isPresented: $showAddTrip) {
            NavigationStack {
                AddTripView()
            }
            .presentationDetents([.medium, .large])
        }
    }
    
    private func deleteTrips(at offsets: IndexSet) {
        withAnimation {
            offsets.map { trips[$0] }.forEach(deleteTrip)
        }
    }
    
    private func deleteTrip(_ trip: Trip) {
        /**
         Unselect the item before deleting it.
         */
        if trip.persistentModelID == selection?.persistentModelID {
            selection = nil
        }
        modelContext.delete(trip)
    }
}

#Preview {
    ContentView()
        .modelContainer(PreviewSampleData.container)
}
