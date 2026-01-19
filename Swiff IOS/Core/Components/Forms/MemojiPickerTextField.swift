//
//  MemojiPickerTextField.swift
//  Swiff IOS
//
//  Created by Naren Reddy on 12/18/25.
//  UIViewRepresentable for capturing Memoji/stickers from iOS keyboard
//

import SwiftUI
import UIKit

/// A text field that captures Memoji and stickers from the iOS keyboard
/// Requires iOS 18.0+ for NSAdaptiveImageGlyph support
@available(iOS 18.0, *)
struct MemojiPickerTextField: UIViewRepresentable {
    @Binding var pickedImage: UIImage?
    var onImagePicked: ((UIImage) -> Void)?

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.supportsAdaptiveImageGlyph = true
        textView.allowsEditingTextAttributes = true
        textView.delegate = context.coordinator
        textView.font = UIFont.systemFont(ofSize: 40)
        textView.textAlignment = .center
        textView.backgroundColor = .clear
        textView.tintColor = UIColor(Color.wiseForestGreen)
        textView.keyboardType = .default
        textView.returnKeyType = .done
        textView.autocorrectionType = .no
        textView.spellCheckingType = .no
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        // No updates needed
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(pickedImage: $pickedImage, onImagePicked: onImagePicked)
    }

    class Coordinator: NSObject, UITextViewDelegate {
        @Binding var pickedImage: UIImage?
        var onImagePicked: ((UIImage) -> Void)?

        init(pickedImage: Binding<UIImage?>, onImagePicked: ((UIImage) -> Void)?) {
            self._pickedImage = pickedImage
            self.onImagePicked = onImagePicked
        }

        func textViewDidChange(_ textView: UITextView) {
            // Check for adaptive image glyph (Memoji/stickers on iOS 18+)
            if let attachment = findFirstAttachment(in: textView.attributedText) {
                handleAttachment(attachment: attachment)
                textView.text = ""
                return
            }

            // Clear any plain text input (we only want images)
            if let text = textView.text, !text.isEmpty {
                // Check if it's a regular emoji - we don't want those here
                // Only accept image attachments
                textView.text = ""
            }
        }

        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            // Dismiss keyboard on return
            if text == "\n" {
                textView.resignFirstResponder()
                return false
            }
            return true
        }

        private func findFirstAttachment(in attributedText: NSAttributedString?) -> NSTextAttachment? {
            guard let attributedText = attributedText else { return nil }

            // Check for adaptive image glyph (iOS 18+ Memoji/stickers)
            var foundGlyph: NSTextAttachment?
            attributedText.enumerateAttribute(.adaptiveImageGlyph,
                                              in: NSRange(location: 0, length: attributedText.length),
                                              options: []) { value, range, stop in
                if let glyph = value as? NSAdaptiveImageGlyph {
                    let attachment = NSTextAttachment()
                    attachment.image = UIImage(data: glyph.imageContent)
                    foundGlyph = attachment
                    stop.pointee = true
                }
            }

            if let foundGlyph = foundGlyph { return foundGlyph }

            // Fallback: check for traditional attachments
            var foundAttachment: NSTextAttachment?
            attributedText.enumerateAttribute(.attachment,
                                              in: NSRange(location: 0, length: attributedText.length),
                                              options: []) { value, range, stop in
                if let attachment = value as? NSTextAttachment {
                    foundAttachment = attachment
                    stop.pointee = true
                }
            }
            return foundAttachment
        }

        private func handleAttachment(attachment: NSTextAttachment) {
            var image: UIImage?

            // Try to get image from attachment
            if let attachmentImage = attachment.image {
                image = attachmentImage
            } else if let attachmentImage = attachment.image(forBounds: attachment.bounds,
                                                              textContainer: nil,
                                                              characterIndex: 0) {
                image = attachmentImage
            } else if let imageData = attachment.fileWrapper?.regularFileContents,
                      let dataImage = UIImage(data: imageData) {
                image = dataImage
            }

            if let image = image {
                self.pickedImage = image
                self.onImagePicked?(image)
            }
        }
    }
}
