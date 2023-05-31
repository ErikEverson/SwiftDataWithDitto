/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The model class of bucket list item.
*/

import Foundation

extension BucketListItem {
    static var preview: BucketListItem {
        let item = BucketListItem()
        item.title = "A bucket list item title"
        item.details = "Details of my bucket list item"
        item.hasReservation = true
        item.isInPlan = true
        item.trip = .preview
        return item
    }
}
