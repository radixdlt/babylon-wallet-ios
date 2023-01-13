@testable import EngineToolkit
import Prelude

// MARK: - DeriveNonFungibleAddressRequestTests
final class DeriveNonFungibleAddressRequestTests: TestCase {
	func test__encodeDecodeAddressRequest() throws {
		try TestSuite.vectors.forEach { try doTest(vector: $0) }
	}
}

private extension DeriveNonFungibleAddressRequestTests {
	func doTest(
		vector: DeriveNonFungibleAddressTestVectors.Vector,
		networkID: NetworkID = .simulator,
		line: UInt = #line
	) throws {
		let request = DeriveNonFungibleAddressRequest(resourceAddress: vector.resourceAddress, nonFungibleId: vector.nonFungibleId)
		let derivedNonfungibleAddress = try sut.deriveNonFungibleAddressRequest(request: request).get()
		XCTAssertNoDifference(derivedNonfungibleAddress.nonFungibleAddress, vector.nonFungibleAddress, line: line)
	}

	typealias TestSuite = DeriveNonFungibleAddressTestVectors
}

// MARK: - DeriveNonFungibleAddressTestVectors
// TODO: Test scenarios have been removed since this request type will be removed and deprecated soon.
enum DeriveNonFungibleAddressTestVectors {
	typealias Vector = (resourceAddress: ResourceAddress, nonFungibleId: NonFungibleId, nonFungibleAddress: NonFungibleAddress)
	static let vectors: [Vector] = []
}
