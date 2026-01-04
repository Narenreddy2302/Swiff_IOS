//
//  PhotoLibraryErrorHandler.swift
//  Swiff IOS
//
//  Created by Claude Code on 11/20/25.
//  Phase 5.2: Comprehensive photo library error handling
//

import SwiftUI
import Photos
import PhotosUI
import UIKit
import Combine

// MARK: - Photo Library Errors

enum PhotoLibraryError: LocalizedError {
    case accessDenied
    case accessRestricted
    case loadingFailed(underlying: Error)
    case invalidFormat(format: String)
    case fileTooLarge(size: Int64, maxSize: Int64)
    case compressionFailed
    case saveFailed(underlying: Error)
    case invalidImageData
    case memoryWarning
    case quotaExceeded(used: Int64, limit: Int64)
    case unsupportedImageType

    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "Photo library access denied. Please enable access in Settings."
        case .accessRestricted:
            return "Photo library access is restricted on this device."
        case .loadingFailed(let error):
            return "Failed to load photo: \(error.localizedDescription)"
        case .invalidFormat(let format):
            return "Unsupported image format: \(format). Please use JPEG, PNG, or HEIC."
        case .fileTooLarge(let size, let maxSize):
            let sizeMB = Double(size) / 1_048_576
            let maxMB = Double(maxSize) / 1_048_576
            return "Image is too large (\(String(format: "%.1f", sizeMB))MB). Maximum size is \(String(format: "%.1f", maxMB))MB."
        case .compressionFailed:
            return "Failed to compress image. Please try a different photo."
        case .saveFailed(let error):
            return "Failed to save photo: \(error.localizedDescription)"
        case .invalidImageData:
            return "Invalid image data. Please try a different photo."
        case .memoryWarning:
            return "Not enough memory to process this image. Please try a smaller photo."
        case .quotaExceeded(let used, let limit):
            let usedMB = Double(used) / 1_048_576
            let limitMB = Double(limit) / 1_048_576
            return "Storage quota exceeded (\(String(format: "%.1f", usedMB))MB of \(String(format: "%.1f", limitMB))MB used)."
        case .unsupportedImageType:
            return "This image type is not supported."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .accessDenied:
            return "Go to Settings > Privacy & Security > Photos and enable access for Swiff."
        case .accessRestricted:
            return "Contact your device administrator to enable photo access."
        case .loadingFailed:
            return "Check your internet connection and try again."
        case .invalidFormat:
            return "Use a standard photo format like JPEG or PNG."
        case .fileTooLarge:
            return "Choose a smaller photo or reduce the image quality in your camera settings."
        case .compressionFailed:
            return "Try selecting a different photo or restart the app."
        case .saveFailed:
            return "Check available storage space and try again."
        case .invalidImageData:
            return "Try selecting a different photo."
        case .memoryWarning:
            return "Close other apps and try again, or choose a smaller photo."
        case .quotaExceeded:
            return "Delete some photos or free up storage space."
        case .unsupportedImageType:
            return "Export the image as JPEG or PNG and try again."
        }
    }
}

// MARK: - Photo Processing Result

struct PhotoProcessingResult {
    let imageData: Data
    let originalSize: Int64
    let compressedSize: Int64
    let compressionRatio: Double
    let format: ImageFormat
    let dimensions: CGSize

    enum ImageFormat: String {
        case jpeg = "JPEG"
        case png = "PNG"
        case heic = "HEIC"
        case unknown = "Unknown"
    }

    var wasCompressed: Bool {
        return compressedSize < originalSize
    }

    var summary: String {
        var info = "Format: \(format.rawValue)\n"
        info += "Dimensions: \(Int(dimensions.width))x\(Int(dimensions.height))\n"
        info += "Original Size: \(formatBytes(originalSize))\n"
        info += "Final Size: \(formatBytes(compressedSize))\n"

        if wasCompressed {
            info += "Compression: \(String(format: "%.1f", compressionRatio * 100))% reduction"
        } else {
            info += "No compression needed"
        }

        return info
    }

    private func formatBytes(_ bytes: Int64) -> String {
        let mb = Double(bytes) / 1_048_576
        if mb >= 1.0 {
            return String(format: "%.2f MB", mb)
        } else {
            let kb = Double(bytes) / 1024
            return String(format: "%.1f KB", kb)
        }
    }
}

// MARK: - Photo Library Error Handler

@MainActor
class PhotoLibraryErrorHandler {

    // MARK: - Configuration

    struct Configuration {
        let maxFileSizeBytes: Int64
        let maxImageDimension: CGFloat
        let compressionQuality: CGFloat
        let allowedFormats: Set<PhotoProcessingResult.ImageFormat>
        let enableAutoCompression: Bool

        nonisolated static let `default` = Configuration(
            maxFileSizeBytes: 10 * 1024 * 1024, // 10 MB
            maxImageDimension: 2048,
            compressionQuality: 0.8,
            allowedFormats: [.jpeg, .png, .heic],
            enableAutoCompression: true
        )

        static let strict = Configuration(
            maxFileSizeBytes: 5 * 1024 * 1024, // 5 MB
            maxImageDimension: 1024,
            compressionQuality: 0.7,
            allowedFormats: [.jpeg, .png],
            enableAutoCompression: true
        )

        static let relaxed = Configuration(
            maxFileSizeBytes: 20 * 1024 * 1024, // 20 MB
            maxImageDimension: 4096,
            compressionQuality: 0.9,
            allowedFormats: [.jpeg, .png, .heic],
            enableAutoCompression: false
        )
    }

    private let configuration: Configuration

    init(configuration: Configuration = .default) {
        self.configuration = configuration
    }

    // MARK: - Permission Handling

    /// Check photo library authorization status
    func checkAuthorizationStatus() async -> PHAuthorizationStatus {
        return PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }

    /// Request photo library access with proper error handling
    func requestAuthorization() async throws -> PHAuthorizationStatus {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)

        switch status {
        case .authorized, .limited:
            return status
        case .denied:
            throw PhotoLibraryError.accessDenied
        case .restricted:
            throw PhotoLibraryError.accessRestricted
        case .notDetermined:
            // This shouldn't happen after requesting, but handle it
            throw PhotoLibraryError.accessDenied
        @unknown default:
            throw PhotoLibraryError.accessDenied
        }
    }

    /// Check if we have photo library access
    func hasPhotoLibraryAccess() async -> Bool {
        let status = await checkAuthorizationStatus()
        return status == .authorized || status == .limited
    }

    // MARK: - Photo Processing

    /// Process photo from PhotosPickerItem with comprehensive error handling
    func processPhoto(from item: PhotosPickerItem) async throws -> PhotoProcessingResult {
        // Load the image data
        guard let data = try? await item.loadTransferable(type: Data.self) else {
            throw PhotoLibraryError.loadingFailed(underlying: NSError(
                domain: "PhotoLibraryErrorHandler",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to load image data"]
            ))
        }

        return try await processImageData(data)
    }

    /// Process raw image data with validation and compression
    func processImageData(_ data: Data) async throws -> PhotoProcessingResult {
        // Validate data is not empty
        guard !data.isEmpty else {
            throw PhotoLibraryError.invalidImageData
        }

        // Check original size
        let originalSize = Int64(data.count)

        // Validate file size (before compression)
        if originalSize > configuration.maxFileSizeBytes * 2 { // Allow 2x for compression
            throw PhotoLibraryError.fileTooLarge(
                size: originalSize,
                maxSize: configuration.maxFileSizeBytes
            )
        }

        // Create UIImage to validate and get metadata
        guard let image = UIImage(data: data) else {
            throw PhotoLibraryError.invalidImageData
        }

        // Check memory constraints
        let estimatedMemoryUsage = image.size.width * image.size.height * 4 // 4 bytes per pixel
        if estimatedMemoryUsage > 100_000_000 { // 100 MB
            throw PhotoLibraryError.memoryWarning
        }

        // Detect format
        let format = detectImageFormat(from: data)

        // Validate format
        guard configuration.allowedFormats.contains(format) else {
            throw PhotoLibraryError.invalidFormat(format: format.rawValue)
        }

        let dimensions = image.size

        // Check if compression is needed
        var finalData = data
        var finalSize = originalSize

        if configuration.enableAutoCompression {
            if originalSize > configuration.maxFileSizeBytes ||
               dimensions.width > configuration.maxImageDimension ||
               dimensions.height > configuration.maxImageDimension {

                // Compress the image
                finalData = try await compressImage(image, targetSize: configuration.maxFileSizeBytes)
                finalSize = Int64(finalData.count)

                // Validate compressed size
                if finalSize > configuration.maxFileSizeBytes {
                    throw PhotoLibraryError.fileTooLarge(
                        size: finalSize,
                        maxSize: configuration.maxFileSizeBytes
                    )
                }
            }
        } else {
            // No auto-compression, validate size as-is
            if originalSize > configuration.maxFileSizeBytes {
                throw PhotoLibraryError.fileTooLarge(
                    size: originalSize,
                    maxSize: configuration.maxFileSizeBytes
                )
            }
        }

        let compressionRatio = 1.0 - (Double(finalSize) / Double(originalSize))

        return PhotoProcessingResult(
            imageData: finalData,
            originalSize: originalSize,
            compressedSize: finalSize,
            compressionRatio: compressionRatio,
            format: format,
            dimensions: dimensions
        )
    }

    // MARK: - Image Compression

    /// Compress image to target size with quality degradation
    private func compressImage(_ image: UIImage, targetSize: Int64) async throws -> Data {
        // First, resize if dimensions are too large
        var processedImage = image

        if image.size.width > configuration.maxImageDimension ||
           image.size.height > configuration.maxImageDimension {
            processedImage = resizeImage(image, maxDimension: configuration.maxImageDimension)
        }

        // Try compression with different quality levels
        var quality = configuration.compressionQuality
        var compressedData: Data?

        for _ in 0..<5 { // Try up to 5 times with decreasing quality
            if let data = processedImage.jpegData(compressionQuality: quality) {
                if data.count <= targetSize {
                    compressedData = data
                    break
                }
            }
            quality -= 0.1 // Reduce quality

            if quality < 0.3 { // Don't go below 30% quality
                break
            }
        }

        guard let finalData = compressedData else {
            throw PhotoLibraryError.compressionFailed
        }

        return finalData
    }

    /// Resize image to fit within max dimension while preserving aspect ratio
    private func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let aspectRatio = size.width / size.height

        var newSize: CGSize
        if size.width > size.height {
            newSize = CGSize(width: maxDimension, height: maxDimension / aspectRatio)
        } else {
            newSize = CGSize(width: maxDimension * aspectRatio, height: maxDimension)
        }

        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return resizedImage ?? image
    }

    // MARK: - Format Detection

    /// Detect image format from data
    private func detectImageFormat(from data: Data) -> PhotoProcessingResult.ImageFormat {
        guard data.count > 12 else { return .unknown }

        // Check JPEG
        if data[0] == 0xFF && data[1] == 0xD8 && data[2] == 0xFF {
            return .jpeg
        }

        // Check PNG
        if data[0] == 0x89 && data[1] == 0x50 && data[2] == 0x4E && data[3] == 0x47 {
            return .png
        }

        // Check HEIC (simplified check)
        if data.count > 12 {
            let heicSignature = data[4..<12]
            if let str = String(data: heicSignature, encoding: .ascii),
               str.contains("ftyp") {
                return .heic
            }
        }

        return .unknown
    }

    // MARK: - Validation

    /// Validate image meets all requirements
    func validateImage(_ data: Data) throws {
        // Check size
        let size = Int64(data.count)
        guard size <= configuration.maxFileSizeBytes else {
            throw PhotoLibraryError.fileTooLarge(
                size: size,
                maxSize: configuration.maxFileSizeBytes
            )
        }

        // Check if valid image
        guard let image = UIImage(data: data) else {
            throw PhotoLibraryError.invalidImageData
        }

        // Check dimensions
        guard image.size.width <= configuration.maxImageDimension &&
              image.size.height <= configuration.maxImageDimension else {
            throw PhotoLibraryError.fileTooLarge(
                size: size,
                maxSize: configuration.maxFileSizeBytes
            )
        }

        // Check format
        let format = detectImageFormat(from: data)
        guard configuration.allowedFormats.contains(format) else {
            throw PhotoLibraryError.invalidFormat(format: format.rawValue)
        }
    }

    // MARK: - Error Recovery

    /// Attempt to recover from photo loading error
    func attemptRecovery(from error: PhotoLibraryError) async -> RecoveryResult {
        switch error {
        case .accessDenied, .accessRestricted:
            return .showSettings
        case .fileTooLarge:
            return .suggestCompression
        case .invalidFormat:
            return .suggestConversion
        case .memoryWarning:
            return .suggestSmallerImage
        case .compressionFailed:
            return .suggestDifferentPhoto
        default:
            return .retry
        }
    }

    enum RecoveryResult {
        case retry
        case showSettings
        case suggestCompression
        case suggestConversion
        case suggestSmallerImage
        case suggestDifferentPhoto

        var userMessage: String {
            switch self {
            case .retry:
                return "Please try again"
            case .showSettings:
                return "Open Settings to grant photo access"
            case .suggestCompression:
                return "Try a smaller photo or enable auto-compression"
            case .suggestConversion:
                return "Convert the image to JPEG or PNG format"
            case .suggestSmallerImage:
                return "Select a smaller photo or close other apps"
            case .suggestDifferentPhoto:
                return "Try selecting a different photo"
            }
        }
    }

    // MARK: - Settings Navigation

    /// Open app settings for photo permissions
    func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            Task { @MainActor in
                UIApplication.shared.open(url)
            }
        }
    }

    // MARK: - Statistics

    /// Get statistics about photo processing
    func getStatistics(for results: [PhotoProcessingResult]) -> String {
        var stats = "=== Photo Processing Statistics ===\n\n"
        stats += "Total Photos Processed: \(results.count)\n"

        let totalOriginalSize = results.reduce(Int64(0)) { $0 + $1.originalSize }
        let totalCompressedSize = results.reduce(Int64(0)) { $0 + $1.compressedSize }
        let compressedCount = results.filter { $0.wasCompressed }.count

        stats += "Total Original Size: \(formatBytes(totalOriginalSize))\n"
        stats += "Total Compressed Size: \(formatBytes(totalCompressedSize))\n"
        stats += "Compressed Photos: \(compressedCount)\n"

        if totalOriginalSize > 0 {
            let overallRatio = 1.0 - (Double(totalCompressedSize) / Double(totalOriginalSize))
            stats += "Overall Compression: \(String(format: "%.1f", overallRatio * 100))%\n"
        }

        // Format breakdown
        let formatCounts = Dictionary(grouping: results) { $0.format }
        stats += "\nFormat Breakdown:\n"
        for (format, photos) in formatCounts {
            stats += "  \(format.rawValue): \(photos.count)\n"
        }

        return stats
    }

    private func formatBytes(_ bytes: Int64) -> String {
        let mb = Double(bytes) / 1_048_576
        if mb >= 1.0 {
            return String(format: "%.2f MB", mb)
        } else {
            let kb = Double(bytes) / 1024
            return String(format: "%.1f KB", kb)
        }
    }
}

// MARK: - Usage Examples (Documentation)

/*
 USAGE EXAMPLES:

 1. Request photo library access:
 ```swift
 let handler = PhotoLibraryErrorHandler()

 do {
     let status = try await handler.requestAuthorization()
     if status == .authorized {
         // Proceed with photo selection
     }
 } catch PhotoLibraryError.accessDenied {
     // Show alert with option to open settings
     handler.openAppSettings()
 } catch {
     // Handle other errors
 }
 ```

 2. Process photo from picker:
 ```swift
 PhotosPicker(selection: $selectedItem, matching: .images) {
     Text("Select Photo")
 }
 .onChange(of: selectedItem) { _, newItem in
     Task {
         guard let item = newItem else { return }

         do {
             let result = try await handler.processPhoto(from: item)
             print(result.summary)

             // Use the processed image data
             avatarImage = result.imageData

         } catch PhotoLibraryError.fileTooLarge(let size, let max) {
             showError("Photo is too large: \(size) bytes (max: \(max))")
         } catch PhotoLibraryError.invalidFormat(let format) {
             showError("Unsupported format: \(format)")
         } catch {
             showError(error.localizedDescription)
         }
     }
 }
 ```

 3. Process with custom configuration:
 ```swift
 let config = PhotoLibraryErrorHandler.Configuration(
     maxFileSizeBytes: 5 * 1024 * 1024,
     maxImageDimension: 1024,
     compressionQuality: 0.7,
     allowedFormats: [.jpeg, .png],
     enableAutoCompression: true
 )

 let handler = PhotoLibraryErrorHandler(configuration: config)
 ```

 4. Error recovery:
 ```swift
 do {
     let result = try await handler.processPhoto(from: item)
 } catch let error as PhotoLibraryError {
     let recovery = await handler.attemptRecovery(from: error)

     switch recovery {
     case .showSettings:
         showSettingsAlert()
     case .suggestCompression:
         // Enable compression and retry
         break
     case .retry:
         // Try again
         break
     default:
         showError(error.localizedDescription)
     }
 }
 ```

 5. Validate existing image data:
 ```swift
 do {
     try handler.validateImage(imageData)
     // Image is valid
 } catch {
     // Image doesn't meet requirements
 }
 ```

 6. Get processing statistics:
 ```swift
 var results: [PhotoProcessingResult] = []

 for item in selectedItems {
     if let result = try? await handler.processPhoto(from: item) {
         results.append(result)
     }
 }

 let stats = handler.getStatistics(for: results)
 print(stats)
 ```
 */
