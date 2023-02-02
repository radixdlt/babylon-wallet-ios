@testable import EngineToolkit
import Prelude

// MARK: - DeriveVirtualIdentityAddressRequestTests
final class DeriveVirtualIdentityAddressRequestTests: TestCase {
	override func setUp() {
		debugPrint = false
		super.setUp()
		continueAfterFailure = false
	}

	func test__encodeDecodeAddressRequest() throws {
		try TestSuite.vectors.forEach { try doTest(vector: $0) }
	}
}

private extension DeriveVirtualIdentityAddressRequestTests {
	func doTest(
		vector: DeriveVirtualIdentityAddressTestVectors.Vector,
		networkID: NetworkID = .simulator,
		line: UInt = #line
	) throws {
		let derivedVirtualIdentityAddress = try sut.deriveVirtualIdentityAddressRequest(
			request: DeriveVirtualIdentityAddressRequest(
				publicKey: vector.publicKey,
				networkId: NetworkID(0xF2)
			)
		).get().virtualIdentityAddress
		XCTAssertNoDifference(
			derivedVirtualIdentityAddress,
			vector.virtualIdentityComponentAddress,
			line: line
		)
	}

	typealias TestSuite = DeriveVirtualIdentityAddressTestVectors
}

// MARK: - DeriveVirtualIdentityAddressTestVectors
enum DeriveVirtualIdentityAddressTestVectors {
	typealias Vector = (publicKey: Engine.PublicKey, virtualIdentityComponentAddress: ComponentAddress)
	static let vectors: [Vector] = [
		(
			publicKey: try! Engine.PublicKey.eddsaEd25519(Engine.EddsaEd25519PublicKey(hex: "1262bc6d5408a3c4e025aa0c15e64f69197cdb38911be5ad344a949779df3da6")),
			virtualIdentityComponentAddress: ComponentAddress(address: "identity_sim1pvazc2z3kaescm47d9qvrmn65pl75j5r5wfr7pcg4njsxm2yr6")
		),
	]
}
