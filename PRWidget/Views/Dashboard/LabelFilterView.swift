import SwiftUI
import CatalystSwift

struct LabelFilterView: View {
    let availableLabels: [String]
    @Binding var selectedLabels: Set<String>
    @Binding var excludedLabels: Set<String>

    var body: some View {
        CollapsibleFilterSection(
            icon: "tag",
            title: "LABELS",
            items: availableLabels,
            selected: $selectedLabels,
            excluded: $excludedLabels
        )
    }
}
