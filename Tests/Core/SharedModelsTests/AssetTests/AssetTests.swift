import EngineKit
import SharedModels
import TestingPrelude

final class AssetTests: TestCase {
	func test_givenNonFungibleTokenAndContainer_outputCorrectNonFungibleGlobalID() throws {
		let rawLocalID = "#123#"
		let localId = try nonFungibleLocalIdFromStr(string: rawLocalID)
		let resourceAddress = try ResourceAddress(validatingAddress: "resource_tdx_d_1nfn7hdrua4wcxwq26qq2gpv2ew0p94k66ms3nmluev6rerr7sszc5z")

		let globalId = try NonFungibleGlobalId.fromParts(resourceAddress: resourceAddress.intoEngine(), nonFungibleLocalId: localId)
		let sut = AccountPortfolio.NonFungibleResource(
			resource: .init(resourceAddress: resourceAddress),
			tokens: [.init(id: globalId, name: nil, description: nil, keyImageURL: nil, metadata: [])]
		)
		let expectedGlobalID = try NonFungibleGlobalId.fromParts(resourceAddress: resourceAddress.intoEngine(), nonFungibleLocalId: localId)
		XCTAssertEqual(globalId, expectedGlobalID)
	}
}
