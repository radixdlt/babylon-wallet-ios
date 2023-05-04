import SharedModels
import TestingPrelude

final class AssetTests: TestCase {
	func test_givenNonFungibleTokenAndContainer_outputCorrectNonFungibleGlobalID() {
		let rawLocalID = "ticket_19206"
		let localId = AccountPortfolio.NonFungibleResource.NonFungibleToken.LocalID(rawValue: rawLocalID)
		let resourceAddress = "resource_1qlq38wvrvh5m4kaz6etaac4389qtuycnp89atc8acdfi"
		let sut = AccountPortfolio.NonFungibleResource(
			resourceAddress: .init(address: resourceAddress),
			tokens: [.init(id: localId, name: nil, description: nil, keyImageURL: nil, metadata: [])]
		)
		let expectedGlobalID = resourceAddress + ":" + rawLocalID
		XCTAssertEqual(sut.nftGlobalID(for: localId), expectedGlobalID)
	}
}
