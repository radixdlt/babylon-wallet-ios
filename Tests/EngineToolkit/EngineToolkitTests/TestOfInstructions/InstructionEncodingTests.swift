import Cryptography
@testable import EngineToolkit
import TestingPrelude

final class InstructionEncodingTests: TestCase {
	override func setUp() {
		debugPrint = false
		super.setUp()
		continueAfterFailure = false
	}

	func test_value_encoding_and_decoding() throws {
		let decoder = JSONDecoder()
		decoder.userInfo[.retCoding] = true
		let raw = try resource(named: "Instructions", extension: "json")
		let instructions = try decoder.decode([Instruction].self, from: raw)

		let encoder = JSONEncoder()
		// encoder.userInfo[.retCoding] = true

		//                let manifest = TransactionManifest(instructions: .parsed([.createAccountAdvanced(.init(config: .init(values: [.map(.init(keyKind: <#T##ManifestASTValueKind#>, valueKind: <#T##ManifestASTValueKind#>, entries: <#T##Map_.Entries#>))])))]))
		//                let str = try RadixEngine.instance.convertManifest(request: .init(manifest: manifest, outputFormat: .string, networkId: .simulator)).get()

		// round trip encode/decoded
		let encoded = try encoder.encode(instructions)
		let decoded = try decoder.decode([Instruction].self, from: encoded)

		XCTAssertEqual(instructions, decoded)
	}
}
