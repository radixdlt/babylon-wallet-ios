@testable import EngineToolkit
import Prelude

// MARK: - DeriveNonFungibleGlobalIdFromPublicKeyRequestTests
final class DeriveNonFungibleGlobalIdFromPublicKeyRequestTests: TestCase {
	override func setUp() {
		debugPrint = true
		super.setUp()
	}

	func test__encodeDecodeAddressRequest() throws {
		try TestSuite.vectors.forEach { try doTest(vector: $0) }
	}
}

private extension DeriveNonFungibleGlobalIdFromPublicKeyRequestTests {
	func doTest(
		vector: DeriveNonFungibleGlobalIdFromPublicKeyTestVectors.Vector,
		networkID: NetworkID = .simulator,
		line: UInt = #line
	) throws {
		let derivedNonFungibleGlobalId = try sut.deriveNonFungibleGlobalIdFromPublicKeyRequest(
			request: DeriveNonFungibleGlobalIdFromPublicKeyRequest(
				publicKey: vector.publicKey,
				networkId: networkID
			)
		).get().nonFungibleGlobalId
		XCTAssertNoDifference(derivedNonFungibleGlobalId, vector.nonFungibleGlobalId, line: line)
	}

	typealias TestSuite = DeriveNonFungibleGlobalIdFromPublicKeyTestVectors
}

// MARK: - DeriveNonFungibleGlobalIdFromPublicKeyTestVectors
// NOTE: We will need to update these test vectors if SBOR gets updated.
enum DeriveNonFungibleGlobalIdFromPublicKeyTestVectors {
	typealias Vector = (publicKey: Engine.PublicKey, nonFungibleGlobalId: NonFungibleGlobalId)
	static let vectors: [Vector] = [
		(
			publicKey: try! .ecdsaSecp256k1(Engine.EcdsaSecp256k1PublicKey(hex: "03d01115d548e7561b15c38f004d734633687cf4419620095bc5b0f47070afe85a")),
			nonFungibleGlobalId: NonFungibleGlobalId(
				resourceAddress: .init(address: "resource_sim1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqshxgp7h"),
				nonFungibleLocalId: try! .bytes(.init(hex: "63535ec6738f7afe1984c128398182a5046cb006f4b6e89af817"))
			)
		),
		(
			publicKey: try! .eddsaEd25519(Engine.EddsaEd25519PublicKey(hex: "1262bc6d5408a3c4e025aa0c15e64f69197cdb38911be5ad344a949779df3da6")),
			nonFungibleGlobalId: NonFungibleGlobalId(
				resourceAddress: .init(address: "resource_sim1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqpqd60rqz"),
				nonFungibleLocalId: try! .bytes(.init(hex: "3a2c2851b7730c6ebe6940c1ee7aa07fea4a83a3923f0708ace5"))
			)
		),
	]
}
