@testable import EngineToolkit
import TestingPrelude

// MARK: - AnalyzeManifestTests
final class AnalyzeManifestTests: TestCase {
	override func setUp() {
		debugPrint = false
		super.setUp()
	}

	func test__analyzeManifest_on_common_manifests_to_parsed_does_not_throw() throws {
		for testVector in try manifestTestVectors() {
			let manifest = TransactionManifest(instructions: .string(testVector.manifest), blobs: testVector.blobs.map { [UInt8]($0) })
			XCTAssertNoThrow(try sut.analyzeManifest(request: .init(manifest: manifest, networkId: 0xF2)).get())
		}
	}
}
