import Foundation
import Resources

// MARK: - AssetBehavior
public enum AssetBehavior: Sendable {
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
	case informationChangeable
	case informationChangeableByAnyone
	case removableByThirdParty
	case removableByAnyone
	case nftDataChangeable
	case nftDataChangeableByAnyone
}

extension AssetBehavior {
	public var description: String {
		switch self {
		case .simpleAsset:
			return L10n.AccountSettings.Behaviors.simpleAsset
		case .supplyIncreasable:
			return L10n.AccountSettings.Behaviors.supplyIncreasable
		case .supplyDecreasable:
			return L10n.AccountSettings.Behaviors.supplyDecreasable
		case .supplyIncreasableByAnyone:
			return L10n.AccountSettings.Behaviors.supplyIncreasableByAnyone
		case .supplyDecreasableByAnyone:
			return L10n.AccountSettings.Behaviors.supplyDecreasableByAnyone
		case .supplyFlexible:
			return L10n.AccountSettings.Behaviors.supplyFlexible
		case .supplyFlexibleByAnyone:
			return L10n.AccountSettings.Behaviors.supplyFlexibleByAnyone
		case .movementRestricted:
			return L10n.AccountSettings.Behaviors.movementRestricted
		case .movementRestrictableInFuture:
			return L10n.AccountSettings.Behaviors.movementRestrictableInFuture
		case .movementRestrictableInFutureByAnyone:
			return L10n.AccountSettings.Behaviors.movementRestrictableInFutureByAnyone
		case .informationChangeable:
			return L10n.AccountSettings.Behaviors.informationChangeable
		case .informationChangeableByAnyone:
			return L10n.AccountSettings.Behaviors.informationChangeableByAnyone
		case .removableByThirdParty:
			return L10n.AccountSettings.Behaviors.removableByThirdParty
		case .removableByAnyone:
			return L10n.AccountSettings.Behaviors.removableByAnyone
		case .nftDataChangeable:
			return L10n.AccountSettings.Behaviors.nftDataChangeable
		case .nftDataChangeableByAnyone:
			return L10n.AccountSettings.Behaviors.nftDataChangeableByAnyone
		}
	}

	public var icon: ImageAsset {
		switch self {
		case .simpleAsset: return AssetResource.simpleAsset
		case .supplyIncreasable: return AssetResource.supplyIncreasable
		case .supplyDecreasable: return AssetResource.supplyDecreasable
		case .supplyIncreasableByAnyone: return AssetResource.supplyIncreasableByAnyone
		case .supplyDecreasableByAnyone: return AssetResource.supplyDecreasableByAnyone
		case .supplyFlexible: return AssetResource.supplyFlexible
		case .supplyFlexibleByAnyone: return AssetResource.supplyFlexibleByAnyone
		case .movementRestrictableInFuture: return AssetResource.movementRestrictableInFuture
		case .movementRestrictableInFutureByAnyone: return AssetResource.movementRestrictableInFutureByAnyone
		case .movementRestricted: return AssetResource.movementRestricted
		case .informationChangeable: return AssetResource.informationChangeable
		case .informationChangeableByAnyone: return AssetResource.informationChangeableByAnyone
		case .removableByThirdParty: return AssetResource.removableByThirdParty
		case .removableByAnyone: return AssetResource.removableByAnyone
		case .nftDataChangeable: return AssetResource.nftDataChangeable
		case .nftDataChangeableByAnyone: return AssetResource.nftDataChangeableByAnyone
		}
	}
}
