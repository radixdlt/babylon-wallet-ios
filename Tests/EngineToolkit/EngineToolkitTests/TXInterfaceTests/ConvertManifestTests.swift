@testable import EngineToolkit
import TestingPrelude

// MARK: - ConvertManifestTests
final class ConvertManifestTests: TestCase {
	override func setUp() {
		debugPrint = false
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

// MARK: - FailingReconvertManifestTests
final class FailingReconvertManifestTests: TestCase {
	override func setUp() {
		debugPrint = false
		super.setUp()
	}

	func test__convertManifest_on_correct_manifest_does_not_throw() throws {
		let correctManifest = try getManifest(named: "reconvert_correct")
		try convertToParsed(manifest: correctManifest)
		try convertToParsedAndBack(manifest: correctManifest)
	}

	// This is almost the same manifest, the only difference is that the name of a Proof has been
	// changed to "0" from "2". This causes a clash with a Bucket("0"), but this only impacts the
	// second step, when it is converted back to a string. Converting it to parsed does work.
	func test__convertManifest_on_incorrect_manifest_does_not_throw() throws {
		let correctManifest = try getManifest(named: "reconvert_incorrect")
		try convertToParsed(manifest: correctManifest)
		try convertToParsedAndBack(manifest: correctManifest)
	}

	private func getManifest(named resourceName: String) throws -> TransactionManifest {
		let manifestString = String(decoding: try resource(named: resourceName, extension: ".rtm"), as: UTF8.self)
		return TransactionManifest(instructions: .string(manifestString), blobs: [])
	}

	private func convertToParsed(manifest: TransactionManifest) throws {
		XCTAssertNoThrow(try sut.convertManifest(request: .init(manifest: manifest, outputFormat: .parsed, networkId: 11)).get())
	}

	private func convertToParsedAndBack(manifest: TransactionManifest) throws {
		let convertedManifest = try sut.convertManifest(request: .init(manifest: manifest, outputFormat: .parsed, networkId: 11)).get()
		XCTAssertNoThrow(try sut.convertManifest(request: .init(manifest: convertedManifest, outputFormat: .string, networkId: 11)).get())
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
