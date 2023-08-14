import Foundation
import Resources

// MARK: - AssetBehavior
public enum AssetBehavior: Sendable, Hashable, Codable, Comparable {
	case simpleAsset

	case supplyIncreasable
	case supplyDecreasable
	case supplyIncreasableByAnyone
	case supplyDecreasableByAnyone
	case supplyFlexible
	case supplyFlexibleByAnyone

	case movementRestricted
	case movementRestrictableInFuture
	case movementRestrictableInFutureByAnyone

	case removableByThirdParty
	case removableByAnyone

	case freezableByThirdParty
	case freezableByAnyone

	case nftDataChangeable
	case nftDataChangeableByAnyone

	// FIXME: Are these not used?
	case informationChangeable
	case informationChangeableByAnyone
}
