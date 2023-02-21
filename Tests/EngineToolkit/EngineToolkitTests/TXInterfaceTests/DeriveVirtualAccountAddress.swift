@testable import EngineToolkit
import Prelude

// MARK: - DeriveVirtualAccountAddressRequestTests
final class DeriveVirtualAccountAddressRequestTests: TestCase {
	override func setUp() {
		debugPrint = false
		super.setUp()
		continueAfterFailure = false
	}

	func test__encodeDecodeAddressRequest() throws {
		try TestSuite.vectors.forEach { try doTest(vector: $0) }
	}
}

extension DeriveVirtualAccountAddressRequestTests {
	private func doTest(
		vector: DeriveVirtualAccountAddressTestVectors.Vector,
		networkID: NetworkID = .simulator,
		line: UInt = #line
	) throws {
		let derivedVirtualAccountAddress = try sut.deriveVirtualAccountAddressRequest(
			request: DeriveVirtualAccountAddressRequest(
				publicKey: vector.publicKey,
				networkId: NetworkID(0xF2)
			)
		).get().virtualAccountAddress
		XCTAssertNoDifference(
			derivedVirtualAccountAddress,
			vector.virtualAccountComponentAddress,
			line: line
		)
	}

	fileprivate typealias TestSuite = DeriveVirtualAccountAddressTestVectors
}

// MARK: - DeriveVirtualAccountAddressTestVectors
enum DeriveVirtualAccountAddressTestVectors {
	typealias Vector = (publicKey: Engine.PublicKey, virtualAccountComponentAddress: ComponentAddress)
	static let vectors: [Vector] = [
		(
			publicKey: try! Engine.PublicKey.eddsaEd25519(Engine.EddsaEd25519PublicKey(hex: "1262bc6d5408a3c4e025aa0c15e64f69197cdb38911be5ad344a949779df3da6")),
			virtualAccountComponentAddress: ComponentAddress(address: "account_sim1pqazc2z3kaescm47d9qvrmn65pl75j5r5wfr7pcg4njs5sn3ng")
		),
	]
}
