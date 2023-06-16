import SharedModels
import TestingPrelude

final class AssetTests: TestCase {
	func test_givenNonFungibleTokenAndContainer_outputCorrectNonFungibleGlobalID() throws {
		let rawLocalID = "#123#"
		let localId = AccountPortfolio.NonFungibleResource.NonFungibleToken.LocalID(rawValue: rawLocalID)
		let resourceAddress = try ResourceAddress(validatingAddress: "resource_sim1thvwu8dh6lk4y9mntemkvj25wllq8adq42skzufp4m8wxxuemugnez")
		let sut = AccountPortfolio.NonFungibleResource(
			resourceAddress: resourceAddress,
			tokens: [.init(id: localId, name: nil, description: nil, keyImageURL: nil, metadata: [])]
		)
		let expectedGlobalID = resourceAddress.address + ":" + rawLocalID
		XCTAssertEqual(sut.nftGlobalID(for: localId), expectedGlobalID)
	}
}
