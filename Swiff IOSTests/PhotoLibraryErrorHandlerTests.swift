//
//  PhotoLibraryErrorHandlerTests.swift
//  Swiff IOSTests
//
//  Created by Claude Code on 11/20/25.
//  Tests for PhotoLibraryErrorHandler - Phase 5.2
//

import XCTest
import Photos
import PhotosUI
@testable import Swiff_IOS

final class PhotoLibraryErrorHandlerTests: XCTestCase {

    var handler: PhotoLibraryErrorHandler!

    override func setUp() {
        super.setUp()
        handler = PhotoLibraryErrorHandler()
    }

    override func tearDown() {
        handler = nil
        super.tearDown()
    }

    // MARK: - Test 1: Configuration Tests

    func testDefaultConfiguration() {
        let config = PhotoLibraryErrorHandler.Configuration.default

        XCTAssertEqual(config.maxFileSizeBytes, 10 * 1024 * 1024) // 10 MB
        XCTAssertEqual(config.maxImageDimension, 2048)
        XCTAssertEqual(config.compressionQuality, 0.8)
        XCTAssertTrue(config.allowedFormats.contains(.jpeg))
        XCTAssertTrue(config.allowedFormats.contains(.png))
        XCTAssertTrue(config.enableAutoCompression)
    }

    func testStrictConfiguration() {
        let config = PhotoLibraryErrorHandler.Configuration.strict

        XCTAssertEqual(config.maxFileSizeBytes, 5 * 1024 * 1024) // 5 MB
        XCTAssertEqual(config.maxImageDimension, 1024)
        XCTAssertEqual(config.compressionQuality, 0.7)
        XCTAssertTrue(config.enableAutoCompression)
    }

    func testRelaxedConfiguration() {
        let config = PhotoLibraryErrorHandler.Configuration.relaxed

        XCTAssertEqual(config.maxFileSizeBytes, 20 * 1024 * 1024) // 20 MB
        XCTAssertEqual(config.maxImageDimension, 4096)
        XCTAssertFalse(config.enableAutoCompression)
    }

    func testCustomConfiguration() {
        let config = PhotoLibraryErrorHandler.Configuration(
            maxFileSizeBytes: 3 * 1024 * 1024,
            maxImageDimension: 512,
            compressionQuality: 0.6,
            allowedFormats: [.jpeg],
            enableAutoCompression: true
        )

        let customHandler = PhotoLibraryErrorHandler(configuration: config)
        XCTAssertNotNil(customHandler)
    }

    // MARK: - Test 2: Image Format Detection

    func testDetectJPEGFormat() async throws {
        // Create a small JPEG image
        let image = createTestImage(size: CGSize(width: 100, height: 100))
        guard let jpegData = image.jpegData(compressionQuality: 1.0) else {
            XCTFail("Failed to create JPEG data")
            return
        }

        let result = try await handler.processImageData(jpegData)
        XCTAssertEqual(result.format, .jpeg)
    }

    func testDetectPNGFormat() async throws {
        // Create a small PNG image
        let image = createTestImage(size: CGSize(width: 100, height: 100))
        guard let pngData = image.pngData() else {
            XCTFail("Failed to create PNG data")
            return
        }

        let result = try await handler.processImageData(pngData)
        XCTAssertEqual(result.format, .png)
    }

    // MARK: - Test 3: Image Validation

    func testValidateValidImage() async throws {
        let image = createTestImage(size: CGSize(width: 500, height: 500))
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            XCTFail("Failed to create image data")
            return
        }

        XCTAssertNoThrow(try handler.validateImage(data))
    }

    func testValidateEmptyData() async throws {
        let emptyData = Data()

        do {
            _ = try await handler.processImageData(emptyData)
            XCTFail("Should throw invalidImageData error")
        } catch PhotoLibraryError.invalidImageData {
            // Expected error
            XCTAssertTrue(true)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testValidateInvalidImageData() async throws {
        let invalidData = "This is not an image".data(using: .utf8)!

        do {
            _ = try await handler.processImageData(invalidData)
            XCTFail("Should throw invalidImageData error")
        } catch PhotoLibraryError.invalidImageData {
            // Expected error
            XCTAssertTrue(true)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - Test 4: File Size Validation

    func testFileSizeWithinLimit() async throws {
        let image = createTestImage(size: CGSize(width: 500, height: 500))
        guard let data = image.jpegData(compressionQuality: 0.5) else {
            XCTFail("Failed to create image data")
            return
        }

        let result = try await handler.processImageData(data)
        XCTAssertLessThanOrEqual(result.compressedSize, 10 * 1024 * 1024)
    }

    func testFileSizeExceedsLimit() async throws {
        // Create handler with very small limit
        let config = PhotoLibraryErrorHandler.Configuration(
            maxFileSizeBytes: 100, // 100 bytes - very small
            maxImageDimension: 2048,
            compressionQuality: 0.8,
            allowedFormats: [.jpeg, .png],
            enableAutoCompression: false
        )
        let strictHandler = PhotoLibraryErrorHandler(configuration: config)

        let image = createTestImage(size: CGSize(width: 500, height: 500))
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            XCTFail("Failed to create image data")
            return
        }

        do {
            _ = try await strictHandler.processImageData(data)
            XCTFail("Should throw fileTooLarge error")
        } catch PhotoLibraryError.fileTooLarge(let size, let maxSize) {
            XCTAssertGreaterThan(size, maxSize)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - Test 5: Image Compression

    func testAutoCompression() async throws {
        // Create a larger image that will need compression
        let image = createTestImage(size: CGSize(width: 1000, height: 1000))
        guard let data = image.jpegData(compressionQuality: 1.0) else {
            XCTFail("Failed to create image data")
            return
        }

        let result = try await handler.processImageData(data)

        // Should be compressed if original was larger than max
        if result.originalSize > 10 * 1024 * 1024 {
            XCTAssertLessThan(result.compressedSize, result.originalSize)
            XCTAssertTrue(result.wasCompressed)
        }
    }

    func testCompressionDisabled() async throws {
        let config = PhotoLibraryErrorHandler.Configuration(
            maxFileSizeBytes: 10 * 1024 * 1024,
            maxImageDimension: 2048,
            compressionQuality: 0.8,
            allowedFormats: [.jpeg, .png],
            enableAutoCompression: false
        )
        let noCompressionHandler = PhotoLibraryErrorHandler(configuration: config)

        let image = createTestImage(size: CGSize(width: 500, height: 500))
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            XCTFail("Failed to create image data")
            return
        }

        let result = try await noCompressionHandler.processImageData(data)

        // Should not compress when disabled and within limits
        XCTAssertEqual(result.originalSize, result.compressedSize)
    }

    // MARK: - Test 6: Image Dimensions

    func testImageDimensionsDetection() async throws {
        let testSize = CGSize(width: 800, height: 600)
        let image = createTestImage(size: testSize)
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            XCTFail("Failed to create image data")
            return
        }

        let result = try await handler.processImageData(data)
        XCTAssertEqual(result.dimensions.width, testSize.width)
        XCTAssertEqual(result.dimensions.height, testSize.height)
    }

    // MARK: - Test 7: Error Recovery

    func testRecoveryFromAccessDenied() async {
        let recovery = await handler.attemptRecovery(from: .accessDenied)

        switch recovery {
        case .showSettings:
            XCTAssertTrue(true)
        default:
            XCTFail("Should suggest showing settings")
        }
    }

    func testRecoveryFromFileTooLarge() async {
        let recovery = await handler.attemptRecovery(from: .fileTooLarge(size: 15_000_000, maxSize: 10_000_000))

        switch recovery {
        case .suggestCompression:
            XCTAssertTrue(true)
        default:
            XCTFail("Should suggest compression")
        }
    }

    func testRecoveryFromInvalidFormat() async {
        let recovery = await handler.attemptRecovery(from: .invalidFormat(format: "BMP"))

        switch recovery {
        case .suggestConversion:
            XCTAssertTrue(true)
        default:
            XCTFail("Should suggest conversion")
        }
    }

    func testRecoveryFromMemoryWarning() async {
        let recovery = await handler.attemptRecovery(from: .memoryWarning)

        switch recovery {
        case .suggestSmallerImage:
            XCTAssertTrue(true)
        default:
            XCTFail("Should suggest smaller image")
        }
    }

    // MARK: - Test 8: Photo Processing Result

    func testPhotoProcessingResultSummary() async throws {
        let image = createTestImage(size: CGSize(width: 500, height: 500))
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            XCTFail("Failed to create image data")
            return
        }

        let result = try await handler.processImageData(data)
        let summary = result.summary

        XCTAssertTrue(summary.contains("Format:"))
        XCTAssertTrue(summary.contains("Dimensions:"))
        XCTAssertTrue(summary.contains("Original Size:"))
        XCTAssertTrue(summary.contains("Final Size:"))
    }

    func testPhotoProcessingWasCompressed() async throws {
        // Create handler that will force compression
        let config = PhotoLibraryErrorHandler.Configuration(
            maxFileSizeBytes: 50 * 1024, // 50 KB
            maxImageDimension: 500,
            compressionQuality: 0.5,
            allowedFormats: [.jpeg, .png],
            enableAutoCompression: true
        )
        let compressingHandler = PhotoLibraryErrorHandler(configuration: config)

        let image = createTestImage(size: CGSize(width: 1000, height: 1000))
        guard let data = image.jpegData(compressionQuality: 1.0) else {
            XCTFail("Failed to create image data")
            return
        }

        let result = try await compressingHandler.processImageData(data)
        XCTAssertTrue(result.wasCompressed)
        XCTAssertGreaterThan(result.compressionRatio, 0)
    }

    // MARK: - Test 9: Statistics

    func testStatisticsWithMultipleResults() async throws {
        var results: [PhotoProcessingResult] = []

        // Process multiple images
        for i in 1...3 {
            let size = CGSize(width: 500 + (i * 100), height: 500 + (i * 100))
            let image = createTestImage(size: size)
            guard let data = image.jpegData(compressionQuality: 0.8) else {
                continue
            }

            if let result = try? await handler.processImageData(data) {
                results.append(result)
            }
        }

        let stats = handler.getStatistics(for: results)

        XCTAssertTrue(stats.contains("Total Photos Processed: \(results.count)"))
        XCTAssertTrue(stats.contains("Format Breakdown:"))
    }

    func testStatisticsWithEmptyResults() {
        let stats = handler.getStatistics(for: [])
        XCTAssertTrue(stats.contains("Total Photos Processed: 0"))
    }

    // MARK: - Test 10: Error Messages

    func testAccessDeniedErrorMessage() {
        let error = PhotoLibraryError.accessDenied
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("access denied"))
        XCTAssertNotNil(error.recoverySuggestion)
    }

    func testFileTooLargeErrorMessage() {
        let error = PhotoLibraryError.fileTooLarge(size: 15_000_000, maxSize: 10_000_000)
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("too large"))
        XCTAssertTrue(error.errorDescription!.contains("MB"))
    }

    func testInvalidFormatErrorMessage() {
        let error = PhotoLibraryError.invalidFormat(format: "BMP")
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("Unsupported"))
        XCTAssertTrue(error.errorDescription!.contains("BMP"))
    }

    func testCompressionFailedErrorMessage() {
        let error = PhotoLibraryError.compressionFailed
        XCTAssertNotNil(error.errorDescription)
        XCTAssertNotNil(error.recoverySuggestion)
    }

    // MARK: - Test 11: Authorization Status

    func testCheckAuthorizationStatus() async {
        let status = await handler.checkAuthorizationStatus()
        // Status can be any valid PHAuthorizationStatus
        XCTAssertTrue([.notDetermined, .restricted, .denied, .authorized, .limited].contains(status))
    }

    func testHasPhotoLibraryAccess() async {
        let hasAccess = await handler.hasPhotoLibraryAccess()
        // Should return a boolean
        XCTAssertTrue(hasAccess == true || hasAccess == false)
    }

    // MARK: - Test 12: Edge Cases

    func testProcessVerySmallImage() async throws {
        let image = createTestImage(size: CGSize(width: 10, height: 10))
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            XCTFail("Failed to create image data")
            return
        }

        let result = try await handler.processImageData(data)
        XCTAssertEqual(result.dimensions.width, 10)
        XCTAssertEqual(result.dimensions.height, 10)
    }

    func testProcessSquareImage() async throws {
        let image = createTestImage(size: CGSize(width: 500, height: 500))
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            XCTFail("Failed to create image data")
            return
        }

        let result = try await handler.processImageData(data)
        XCTAssertEqual(result.dimensions.width, result.dimensions.height)
    }

    func testProcessWideImage() async throws {
        let image = createTestImage(size: CGSize(width: 1000, height: 500))
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            XCTFail("Failed to create image data")
            return
        }

        let result = try await handler.processImageData(data)
        XCTAssertGreaterThan(result.dimensions.width, result.dimensions.height)
    }

    func testProcessTallImage() async throws {
        let image = createTestImage(size: CGSize(width: 500, height: 1000))
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            XCTFail("Failed to create image data")
            return
        }

        let result = try await handler.processImageData(data)
        XCTAssertLessThan(result.dimensions.width, result.dimensions.height)
    }

    // MARK: - Helper Methods

    private func createTestImage(size: CGSize, color: UIColor = .blue) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }
}
