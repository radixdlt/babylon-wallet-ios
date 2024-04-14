import Foundation
import Sargon

extension ResourceOrNonFungible {
	public var resourceAddress: ResourceAddress {
//		switch self {
//		case let .resourceAddress(address):
//			address
//		case let .nonFungibleGlobalID(nonFungibleGlobalID):
//			nonFungibleGlobalID.resourceAddress
//		}
		sargonProfileFinishMigrateAtEndOfStage1()
	}
}
