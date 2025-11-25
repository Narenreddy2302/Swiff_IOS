//
//  ValidatedTextField.swift
//  Swiff IOS
//
//  Created by Naren Reddy on 11/20/25.
//  Text field with built-in validation and error display
//

import SwiftUI

struct ValidatedTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let keyboardType: UIKeyboardType
    let errorMessage: String?
    let onValidate: ((String) -> Bool)?

    init(
        title: String,
        placeholder: String,
        text: Binding<String>,
        keyboardType: UIKeyboardType = .default,
        errorMessage: String? = nil,
        onValidate: ((String) -> Bool)? = nil
    ) {
        self.title = title
        self.placeholder = placeholder
        self._text = text
        self.keyboardType = keyboardType
        self.errorMessage = errorMessage
        self.onValidate = onValidate
    }

    var hasError: Bool {
        errorMessage != nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.spotifyLabelMedium)
                .foregroundColor(.wiseSecondaryText)

            TextField(placeholder, text: $text)
                .font(.spotifyBodyMedium)
                .foregroundColor(.wisePrimaryText)
                .keyboardType(keyboardType)
                .textInputAutocapitalization(keyboardType == .emailAddress ? .never : .words)
                .autocorrectionDisabled(keyboardType == .emailAddress)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.wiseBorder.opacity(0.3))
                        .stroke(hasError ? Color.wiseError : Color.wiseBorder, lineWidth: hasError ? 2 : 1)
                )
                .onChange(of: text) { oldValue, newValue in
                    if let onValidate = onValidate {
                        _ = onValidate(newValue)
                    }
                }

            if let errorMessage = errorMessage {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 12))
                    Text(errorMessage)
                        .font(.spotifyCaptionMedium)
                }
                .foregroundColor(.wiseError)
            }
        }
    }
}

struct ValidatedAmountField: View {
    let title: String
    @Binding var amount: Double
    let errorMessage: String?
    let currencySymbol: String

    init(
        title: String = "Amount",
        amount: Binding<Double>,
        errorMessage: String? = nil,
        currencySymbol: String = "$"
    ) {
        self.title = title
        self._amount = amount
        self.errorMessage = errorMessage
        self.currencySymbol = currencySymbol
    }

    var hasError: Bool {
        errorMessage != nil
    }

    @State private var textValue: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.spotifyLabelMedium)
                .foregroundColor(.wiseSecondaryText)

            HStack(spacing: 12) {
                Text(currencySymbol)
                    .font(.spotifyBodyLarge)
                    .foregroundColor(.wisePrimaryText)

                TextField("0.00", text: $textValue)
                    .font(.spotifyBodyMedium)
                    .foregroundColor(.wisePrimaryText)
                    .keyboardType(.decimalPad)
                    .onChange(of: textValue) { oldValue, newValue in
                        // Allow only numbers and one decimal point
                        let filtered = newValue.filter { $0.isNumber || $0 == "." }
                        if filtered != newValue {
                            textValue = filtered
                        }

                        // Update amount
                        if let value = Double(filtered) {
                            amount = value
                        } else if filtered.isEmpty {
                            amount = 0
                        }
                    }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.wiseBorder.opacity(0.3))
                    .stroke(hasError ? Color.wiseError : Color.wiseBorder, lineWidth: hasError ? 2 : 1)
            )

            if let errorMessage = errorMessage {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 12))
                    Text(errorMessage)
                        .font(.spotifyCaptionMedium)
                }
                .foregroundColor(.wiseError)
            }
        }
        .onAppear {
            if amount > 0 {
                textValue = String(format: "%.2f", amount)
            }
        }
    }
}

#Preview {
    VStack(spacing: 24) {
        ValidatedTextField(
            title: "Name",
            placeholder: "Enter your name",
            text: .constant("John Doe"),
            errorMessage: nil
        )

        ValidatedTextField(
            title: "Email",
            placeholder: "your.email@example.com",
            text: .constant("invalid-email"),
            keyboardType: .emailAddress,
            errorMessage: "Please enter a valid email address"
        )

        ValidatedAmountField(
            title: "Amount",
            amount: .constant(25.50),
            errorMessage: nil
        )

        ValidatedAmountField(
            title: "Amount",
            amount: .constant(0),
            errorMessage: "Amount must be greater than zero"
        )
    }
    .padding()
    .background(Color.wiseBackground)
}
