import SwiftUI
import CatalystSwift

struct AuthorFilterView: View {
    let availableAuthors: [String]
    @Binding var selectedAuthors: Set<String>
    @Binding var excludedAuthors: Set<String>

    var body: some View {
        CollapsibleFilterSection(
            icon: "person",
            title: "AUTHORS",
            items: availableAuthors,
            selected: $selectedAuthors,
            excluded: $excludedAuthors
        )
    }
}
