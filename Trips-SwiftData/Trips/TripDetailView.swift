/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A SwiftUI view that shows the details of a trip.
*/

import SwiftUI

struct TripDetailView: View {
    var trip: Trip
    
    var body: some View {
        List {
            #if os(macOS)
            tripInfoViewForMac()
            #else
            tripInfoViewForiOS()
            #endif
        }
        .navigationTitle(Text("Trip Details"))
    }
    
    @ViewBuilder
    private func tripInfoViewForMac() -> some View {
        Section {
            TripGroupBox {
                HStack {
                    VStack(alignment: .leading) {
                        Text(trip.displayDestination)
                        if case let (start?, end?) = (trip.startDate, trip.endDate) {
                            HStack {
                                Text(start, style: .date)
                                Image(systemName: "arrow.right")
                                Text(end, style: .date)
                            }
                        }
                    }
                    Spacer()
                }
            }
        } header: {
            HStack {
                Text(trip.displayName)
                    .font(.title)
                Spacer()
                NavigationLink {
                    UpdateTripView(trip: trip)
                } label: {
                    Label("Edit", systemImage: "chevron.right")
                        .labelStyle(.iconOnly)
                }
            }
        }
        Section {
            TripGroupBox {
                HStack {
                    VStack(alignment: .leading) {
                        if let livingAccommodation = trip.livingAccommodation {
                            Text(livingAccommodation.displayPlaceName)
                            Text(livingAccommodation.displayAddress)
                        } else {
                            Text("<No Living Accommodations>")
                        }
                    }
                    Spacer()
                }
            }
        } header: {
            HStack {
                Text("Living Accommodations").font(.headline)
                Spacer()
                NavigationLink {
                    EditLivingAccommodationsView(trip: trip)
                } label: {
                    Label("Edit", systemImage: "chevron.right")
                        .labelStyle(.iconOnly)
                }
            }
        }
        Section {
        } header: {
            HStack {
                Text("Bucket List").font(.headline)
                Spacer()
                NavigationLink {
                    BucketListView(trip: trip)
                } label: {
                    Label("View", systemImage: "chevron.right")
                        .labelStyle(.iconOnly)
                }
            }
        }
    }

    @ViewBuilder
    private func tripInfoViewForiOS() -> some View {
        VStack(alignment: .leading) {
            Text(trip.displayName)
                .font(.title)
                .bold()
            Text(trip.displayDestination)

            if case let (start?, end?) = (trip.startDate, trip.endDate) {
                HStack {
                    Text(start, style: .date)
                    Image(systemName: "arrow.right")
                    Text(end, style: .date)
                }
            }
        }
        NavigationLink {
            UpdateTripView(trip: trip)
        } label: {
            Text("Change Trip Details")
        }

        Section {
            VStack(alignment: .leading) {
                if let livingAccommodation = trip.livingAccommodation {
                    Text(livingAccommodation.displayPlaceName)
                    Text(livingAccommodation.displayAddress)
                } else {
                    Text("<No Living Accommodations>")
                }
            }
            NavigationLink {
                EditLivingAccommodationsView(trip: trip)
            } label: {
                Text("Change Living Accommodations")
            }
        } header: {
            Text("Living Accommodations")
        }

        Section {
            NavigationLink {
                BucketListView(trip: trip)
            } label: {
                Text("View Bucket List")
            }
        } header: {
            Text("Bucket List")
        }
    }
}

#Preview {
    ModelContainerPreview(PreviewSampleData.inMemoryContainer) {
        TripDetailView(trip: .preview)
    }
}
