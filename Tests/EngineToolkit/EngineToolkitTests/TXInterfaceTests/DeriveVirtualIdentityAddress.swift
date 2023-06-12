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

extension DeriveVirtualIdentityAddressRequestTests {
	private func doTest(
		vector: DeriveVirtualIdentityAddressTestVectors.Vector,
		networkID: NetworkID = .simulator,
		line: UInt = #line
	) throws {
		let derivedVirtualIdentityAddress = try sut.deriveVirtualIdentityAddressRequest(
			request: DeriveVirtualIdentityAddressRequest(
				publicKey: vector.publicKey,
				networkId: networkID
			)
		).get().virtualIdentityAddress
		XCTAssertNoDifference(
			derivedVirtualIdentityAddress,
			vector.virtualIdentityComponentAddress,
			line: line
		)
	}

	fileprivate typealias TestSuite = DeriveVirtualIdentityAddressTestVectors
}

// MARK: - DeriveVirtualIdentityAddressTestVectors
enum DeriveVirtualIdentityAddressTestVectors {
	typealias Vector = (publicKey: Engine.PublicKey, virtualIdentityComponentAddress: IdentityAddress)
	static let vectors: [Vector] = [
		(
			publicKey: try! .eddsaEd25519(.init(hex: "1262bc6d5408a3c4e025aa0c15e64f69197cdb38911be5ad344a949779df3da6")),
			virtualIdentityComponentAddress: try! .init(validatingAddress: "identity_sim1ps4zv7pqlfq8tqqns9qqreegtct6r3n8kcq0ag3q7v7sen32fx")
		),
	]
}
