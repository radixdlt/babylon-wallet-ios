import Cryptography
@testable import EngineToolkit
import TestingPrelude

final class ValueEncodingTests: TestCase {
	override func setUp() {
		debugPrint = false
		super.setUp()
		continueAfterFailure = false
	}

	func test_value_encoding_and_decoding() throws {
		let resourceAddress = try ResourceAddress(validatingAddress: "resource_rdx1tknxxxxxxxxxradxrdxxxxxxxxx009923554798xxxxxxxxxradxrd")
		let componentAddress = try ComponentAddress(validatingAddress: "component_rdx1cptxxxxxxxxxfaucetxxxxxxxxx000527798379xxxxxxxxxfaucet")
		let packageAddress = try PackageAddress(validatingAddress: "package_rdx1pkgxxxxxxxxxfaucetxxxxxxxxx000034355863xxxxxxxxxfaucet")

		// load all manifests
		let decoder = JSONDecoder()
		decoder.userInfo[.retCoding] = true
		let testValues = try decoder.decode([ManifestASTValue].self, from: resource(named: "ManifestAstValue", extension: "json"))

		let instructions: [any InstructionProtocol] = [
			TakeAllFromWorktop(resourceAddress: resourceAddress, bucket: .init(value: "bucket1")),
			CreateProofFromAuthZone(resourceAddress: resourceAddress, intoProof: .init(identifier: "proof1")),
			CallMethod(receiver: componentAddress, methodName: "aliases", arguments: testValues),
		]

		let manifest = TransactionManifest(instructions: .parsed(instructions.map { $0.embed() }), blobs: [[10], [10]])

		let stringManifest = try RadixEngine.instance.convertManifest(request: .init(manifest: manifest, outputFormat: .string, networkId: .mainnet)).get()

		let roundTripManifest = try RadixEngine.instance.convertManifest(request: .init(manifest: stringManifest, outputFormat: .parsed, networkId: .mainnet)).get()

		XCTAssertEqual(roundTripManifest.instructions, manifest.instructions)
	}
}
