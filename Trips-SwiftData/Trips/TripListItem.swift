/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A SwiftUI list item view that shows trip metadata.
*/

import SwiftUI

struct TripListItem: View {
    var trip: Trip
    
    var body: some View {
        NavigationLink(value: trip) {
            HStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(trip.color)
                    .frame(width: 64, height: 64)
                    .overlay {
                        Text(String(trip.displayName.first!))
                            .font(.system(size: 48))
                            .foregroundStyle(.background)
                    }
                    .padding(.trailing)
                
                VStack(alignment: .leading) {
                    Text(trip.displayName)
                        .font(.headline)
                    Text(trip.displayDestination)
                        .font(.subheadline)
                    
                    if case let (start?, end?) = (trip.startDate, trip.endDate) {
                        Divider()
                        HStack {
                            Text(start, style: .date)
                            Image(systemName: "arrow.right")
                            Text(end, style: .date)
                        }
                        .font(.caption)
                    }
                }
            }
        }
    }
}

#Preview {
    ModelContainerPreview(PreviewSampleData.inMemoryContainer) {
        List {
            TripListItem(trip: .preview)
        }
    }
}
