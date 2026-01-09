//
//  TransactionModalView.swift
//  iMessageTransactionUI
//
//  Description:
//  Modal sheet for creating a new transaction.
//  Contains form fields for all transaction details.
//
//  Layout:
//  - NavigationView with:
//    - Header: Cancel button, title, Create button
//    - Form fields:
//      1. Transaction Name (text field)
//      2. Total Bill (number field)
//      3. Paid By (text field)
//      4. Split Method (picker/dropdown)
//      5. Who are all involved (tagging input)
//
//  Validation:
//  - Create button disabled until form is valid
//  - All fields except Split Method are required
//  - Total Bill must be > 0
//  - At least one person must be added
//
//  Functionality:
//  - Cancel: Closes modal and resets form
//  - Create: Creates transaction and closes modal
//  - People input: Press Enter to add, Backspace to remove last
//
//  Properties:
//  - viewModel: ChatViewModel - The view model to interact with
//

import SwiftUI

// MARK: - TransactionModalView
/// Modal sheet for creating a new transaction
struct TransactionModalView: View {
    
    // MARK: - Properties
    
    /// The view model to interact with
    @ObservedObject var viewModel: ChatViewModel
    
    /// Environment variable for dismissing the sheet
    @Environment(\.dismiss) private var dismiss
    
    /// Focus state for the person input field
    @FocusState private var isPersonInputFocused: Bool
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Transaction Name
                    formField(
                        label: "TRANSACTION NAME",
                        placeholder: "e.g., Dinner at Restaurant",
                        text: $viewModel.transactionName
                    )
                    
                    // Total Bill
                    formField(
                        label: "TOTAL BILL",
                        placeholder: "0.00",
                        text: $viewModel.totalBillString,
                        keyboardType: .decimalPad
                    )
                    
                    // Paid By
                    formField(
                        label: "PAID BY",
                        placeholder: "Enter name",
                        text: $viewModel.paidBy
                    )
                    
                    // Split Method
                    splitMethodPicker
                    
                    // People Involved
                    peopleInvolvedSection
                }
                .padding(24)
            }
            .background(Color.white)
            .navigationTitle("New Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Cancel button
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        viewModel.closeTransactionModal()
                        dismiss()
                    }
                    .foregroundColor(.iMessageBlue)
                }
                
                // Create button
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        viewModel.createTransaction()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(viewModel.isFormValid ? .iMessageBlue : .disabled)
                    .disabled(!viewModel.isFormValid)
                }
            }
        }
    }
    
    // MARK: - Form Field
    /// Reusable form field component
    /// - Parameters:
    ///   - label: The label text above the field
    ///   - placeholder: Placeholder text for the field
    ///   - text: Binding to the text value
    ///   - keyboardType: The keyboard type to use (default: .default)
    private func formField(
        label: String,
        placeholder: String,
        text: Binding<String>,
        keyboardType: UIKeyboardType = .default
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Label
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.textSecondary)
                .tracking(0.5)
            
            // Input field
            TextField(placeholder, text: text)
                .font(.system(size: 17))
                .keyboardType(keyboardType)
                .inputFieldStyle()
        }
    }
    
    // MARK: - Split Method Picker
    /// Dropdown picker for selecting split method
    private var splitMethodPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Label
            Text("SPLIT METHOD")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.textSecondary)
                .tracking(0.5)
            
            // Picker
            Menu {
                ForEach(viewModel.splitMethodOptions, id: \.self) { option in
                    Button(option) {
                        viewModel.splitMethod = option
                    }
                }
            } label: {
                HStack {
                    Text(viewModel.splitMethod)
                        .font(.system(size: 17))
                        .foregroundColor(.textPrimary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14))
                        .foregroundColor(.textSecondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.inputBorder, lineWidth: 1)
                )
            }
        }
    }
    
    // MARK: - People Involved Section
    /// Section for adding/removing people from the transaction
    private var peopleInvolvedSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Label
            Text("WHO ARE ALL INVOLVED")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.textSecondary)
                .tracking(0.5)
            
            // People tags container
            peopleTagsContainer
        }
    }
    
    /// Container for people tags and input field
    private var peopleTagsContainer: some View {
        FlowLayout(spacing: 8) {
            // Existing person tags
            ForEach(viewModel.people, id: \.self) { person in
                PersonTagView(name: person) {
                    viewModel.removePerson(person)
                }
            }
            
            // Input field for adding new people
            personInputField
        }
        .padding(12)
        .frame(minHeight: 52)
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isPersonInputFocused ? Color.iMessageBlue : Color.inputBorder, lineWidth: 1)
        )
        .onTapGesture {
            isPersonInputFocused = true
        }
    }
    
    /// Text field for adding new people
    private var personInputField: some View {
        TextField("Type name and press Enter", text: $viewModel.personInputText)
            .font(.system(size: 17))
            .focused($isPersonInputFocused)
            .frame(minWidth: 150)
            .onSubmit {
                if !viewModel.personInputText.isEmpty {
                    viewModel.addPerson(viewModel.personInputText)
                }
            }
            .onChange(of: viewModel.personInputText) { newValue in
                // Handle backspace on empty field
                // Note: This is a simplified approach
                // In production, you might use a custom UIViewRepresentable
            }
    }
}

// MARK: - Flow Layout
/// A layout that arranges views in a flowing grid pattern
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                       y: bounds.minY + result.positions[index].y),
                         proposal: ProposedViewSize(result.sizes[index]))
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        var sizes: [CGSize] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0
            var maxWidth: CGFloat = maxWidth
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                sizes.append(size)
                
                if currentX + size.width > maxWidth && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }
                
                positions.append(CGPoint(x: currentX, y: currentY))
                lineHeight = max(lineHeight, size.height)
                currentX += size.width + spacing
                
                self.size.width = max(self.size.width, currentX - spacing)
            }
            
            self.size.height = currentY + lineHeight
        }
    }
}

// MARK: - Preview
#Preview {
    TransactionModalView(viewModel: ChatViewModel())
}
