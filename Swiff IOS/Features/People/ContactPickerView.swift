import Contacts
import ContactsUI
import SwiftUI

// MARK: - Contact Picker View
struct ContactPickerView: UIViewControllerRepresentable {
    @Binding var name: String
    @Binding var email: String
    @Binding var phone: String
    @Binding var isPresented: Bool

    func makeUIViewController(context: Context) -> CNContactPickerViewController {
        let picker = CNContactPickerViewController()
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: CNContactPickerViewController, context: Context)
    {}

    func makeCoordinator() -> Coordinator {
        Coordinator(name: $name, email: $email, phone: $phone, isPresented: $isPresented)
    }

    class Coordinator: NSObject, CNContactPickerDelegate {
        @Binding var name: String
        @Binding var email: String
        @Binding var phone: String
        @Binding var isPresented: Bool

        init(
            name: Binding<String>, email: Binding<String>, phone: Binding<String>,
            isPresented: Binding<Bool>
        ) {
            _name = name
            _email = email
            _phone = phone
            _isPresented = isPresented
        }

        func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
            // Extract name
            let fullName = CNContactFormatter.string(from: contact, style: .fullName) ?? ""
            name = fullName

            // Extract email
            if let firstEmail = contact.emailAddresses.first {
                email = firstEmail.value as String
            }

            // Extract phone
            if let firstPhone = contact.phoneNumbers.first {
                phone = firstPhone.value.stringValue
            }

            isPresented = false
        }

        func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
            isPresented = false
        }
    }
}
