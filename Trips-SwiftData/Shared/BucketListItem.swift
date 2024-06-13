/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The model class of bucket list items.
*/

import Foundation
import SwiftData

@Model class BucketListItem {
    var dittoId: String
    var collectionName: String = "bucketList"
    var title: String
    var details: String
    var hasReservation: Bool
    var isInPlan: Bool
    var trip: Trip?
    
    init(dittoId: String, title: String, details: String, hasReservation: Bool, isInPlan: Bool) {
        self.dittoId = dittoId
        self.title = title
        self.details = details
        self.hasReservation = hasReservation
        self.isInPlan = isInPlan
    }
}

extension BucketListItem {
    static var preview: BucketListItem {
        let item = BucketListItem(
            dittoId: UUID().uuidString,
            title: "A bucket list item title",
            details: "Details of my bucket list item",
            hasReservation: true, isInPlan: true)
        item.trip = .preview
        return item
    }
    
    static var previewBLTs: [BucketListItem] {
        [
            BucketListItem(
                dittoId: UUID().uuidString,
                title: "See Half Dome",
                details: "try to climb Half Dome",
                hasReservation: true, isInPlan: false),
            BucketListItem(
                dittoId: UUID().uuidString,
                title: "Picture at the falls",
                details: "get a lot of them!",
                hasReservation: true, isInPlan: false)
        ]
    }
}
