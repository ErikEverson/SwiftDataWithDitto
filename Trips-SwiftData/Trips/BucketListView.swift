/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A SwiftUI view that shows the bucket list.
*/

import SwiftUI
import SwiftData

struct BucketListView: View {
    var trip: Trip

    @Environment(\.modelContext) private var modelContext
    
    @State private var showAddItem = false
    @State private var searchText = ""
        
    var body: some View {
        TripForm {
            ForEach(filteredBucketList, id: \.self) { item in
                TripGroupBox {
                    NavigationLink {
                        BucketListItemView(item: item)
                    } label: {
                        HStack {
                            Text(item.title)
                            Spacer()
                            BucketListItemToggle(item: item)
                            #if os(macOS)
                            Image(systemName: "chevron.right")
                                .font(.system(.footnote).weight(.semibold))
                            #endif
                        }
                    }
                }
            }
            .onDelete(perform: deleteItems(at:))
        }
        .searchable(text: $searchText)
        .navigationTitle("Bucket List")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                EditButton()
                    .disabled(filteredBucketList.isEmpty)
            }
            ToolbarItemGroup(placement: .bottomBar) {
                Spacer()
                Button {
                    showAddItem.toggle()
                } label: {
                    Label("Add", systemImage: "square.and.pencil")
                }
            }
        }
        .sheet(isPresented: $showAddItem) {
            NavigationStack {
                AddBucketListItemView(trip: trip)
                    .presentationDetents([.medium, .large])
            }
        }
    }
    
    var filteredBucketList: [BucketListItem] {
        if searchText.isEmpty {
            return trip.bucketList
        }
        
        let tripName = trip.name
        let filteredList = try? trip.bucketList.filter(#Predicate { item in
            item.title.contains(searchText) && tripName == item.trip?.name
        })

        return filteredList ?? []
    }
    
    private func deleteItems(at offsets: IndexSet) {
        withAnimation {
            offsets.forEach {
                let item = trip.bucketList[$0]
                modelContext.delete(item)
            }
        }
    }
}

struct BucketListItemToggle: View {
    @Bindable var item: BucketListItem
    
    var body: some View {
        Toggle("Bucket list item is in plan", isOn: $item.isInPlan)
            .labelsHidden()
    }
}

@MainActor #Preview {
    BucketListView(trip: .preview)
        .modelContainer(PreviewSampleData.container)
}
