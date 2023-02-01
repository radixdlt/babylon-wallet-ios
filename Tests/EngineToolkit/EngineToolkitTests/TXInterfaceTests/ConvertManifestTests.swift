@testable import EngineToolkit
import TestingPrelude

// MARK: - ConvertManifestTests
final class ConvertManifestTests: TestCase {
	override func setUp() {
		debugPrint = true
		super.setUp()
	}

	func test__convertManifest_on_common_manifests_to_parsed_does_not_throw() throws {
		for testVector in try manifestTestVectors() {
			let manifest = TransactionManifest(instructions: .string(testVector.manifest), blobs: testVector.blobs.map { [UInt8]($0) })
			XCTAssertNoThrow(try sut.convertManifest(request: .init(manifest: manifest, outputFormat: .parsed, networkId: 0xF2)).get())
		}
	}

	func test__convertManifest_on_common_manifests_to_parsed_then_to_string_does_not_throw() throws {
		for testVector in try manifestTestVectors() {
			let manifest = TransactionManifest(instructions: .string(testVector.manifest), blobs: testVector.blobs.map { [UInt8]($0) })
			let convertedManifest = try sut.convertManifest(request: .init(manifest: manifest, outputFormat: .parsed, networkId: 0xF2)).get()
			XCTAssertNoThrow(try sut.convertManifest(request: .init(manifest: convertedManifest, outputFormat: .string, networkId: 0xF2)).get())
		}
	}
}

func makeRequest(
	outputFormat: ManifestInstructionsKind = .parsed,
	manifest: TransactionManifest
) -> ConvertManifestRequest {
	ConvertManifestRequest(
		manifest: manifest,
		outputFormat: outputFormat,
		networkId: .simulator
	)
}
