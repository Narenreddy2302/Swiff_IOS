import ContactsUI
import SwiftUI

@available(iOS 18.0, *)
struct ContactAccessButtonView: View {
    let onContactsSelected: ([String]) -> Void
    @State private var searchQuery = ""

    var body: some View {
        // ContactAccessButton is available in iOS 18+ to allow users to grant access to more contacts
        // The button itself handles the UI for picking contacts
        // Note: The completion handler receives contact identifiers directly (not a Result type)
        ContactAccessButton(queryString: searchQuery) { identifiers in
            onContactsSelected(identifiers)
        }
        .frame(height: 44)
        .cornerRadius(22)
    }
}
