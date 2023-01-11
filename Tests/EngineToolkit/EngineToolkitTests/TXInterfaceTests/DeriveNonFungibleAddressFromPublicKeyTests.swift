@testable import EngineToolkit
import Prelude

// MARK: - DeriveNonFungibleAddressFromPublicKeyRequestTests
final class DeriveNonFungibleAddressFromPublicKeyRequestTests: TestCase {
	func test__encodeDecodeAddressRequest() throws {
		try TestSuite.vectors.forEach { try doTest(vector: $0) }
	}
}

private extension DeriveNonFungibleAddressFromPublicKeyRequestTests {
	func doTest(
		vector: DeriveNonFungibleAddressFromPublicKeyTestVectors.Vector,
		networkID: NetworkID = .simulator,
		line: UInt = #line
	) throws {
		let derivedNonfungibleAddress = try sut.deriveNonFungibleAddressFromPublicKeyRequest(
			request: DeriveNonFungibleAddressFromPublicKeyRequest(
				publicKey: vector.publicKey,
				networkId: networkID
			)
		).get()
		XCTAssertNoDifference(derivedNonfungibleAddress.nonFungibleAddress, vector.nonFungibleAddress, line: line)
	}

	typealias TestSuite = DeriveNonFungibleAddressFromPublicKeyTestVectors
}

// MARK: - DeriveNonFungibleAddressFromPublicKeyTestVectors
// NOTE: We will need to update these test vectors if SBOR gets updated.
enum DeriveNonFungibleAddressFromPublicKeyTestVectors {
	typealias Vector = (publicKey: Engine.PublicKey, nonFungibleAddress: NonFungibleAddress)
	static let vectors: [Vector] = [
		(
			publicKey: try! .ecdsaSecp256k1(Engine.EcdsaSecp256k1PublicKey(hex: "03d01115d548e7561b15c38f004d734633687cf4419620095bc5b0f47070afe85a")),
			nonFungibleAddress: NonFungibleAddress(
				resourceAddress: .init(address: "resource_sim1qzu3wdlw3fx7t82fmt2qme2kpet4g3n2epx02sew49wsyz7uhu"),
				nonFungibleId: try! .bytes(.init(hex: "63535ec6738f7afe1984c128398182a5046cb006f4b6e89af817"))
			)
		),
		(
			publicKey: try! .eddsaEd25519(Engine.EddsaEd25519PublicKey(hex: "1262bc6d5408a3c4e025aa0c15e64f69197cdb38911be5ad344a949779df3da6")),
			nonFungibleAddress: NonFungibleAddress(
				resourceAddress: .init(address: "resource_sim1qq8cays25704xdyap2vhgmshkkfyr023uxdtk59ddd4qs8cr5v"),
				nonFungibleId: try! .bytes(.init(hex: "3a2c2851b7730c6ebe6940c1ee7aa07fea4a83a3923f0708ace5"))
			)
		),
	]
}
