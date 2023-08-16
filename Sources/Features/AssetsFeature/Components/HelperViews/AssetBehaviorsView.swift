import EngineKit
import FeaturePrelude
import SharedModels

// MARK: - AssetBehaviorsView
struct AssetBehaviorsView: View {
	let behaviors: [AssetBehavior]

	var body: some View {
		if !behaviors.isEmpty {
			Text(L10n.AssetDetails.behavior)
				.textStyle(.body1Regular)
				.foregroundColor(.app.gray2)

			VStack(alignment: .leading, spacing: .small1) {
				ForEach(behaviors, id: \.self) { behavior in
					AssetBehaviorRow(behavior: behavior)
				}
			}
		}
	}
}

// MARK: - AssetBehaviorRow
struct AssetBehaviorRow: View {
	let behavior: AssetBehavior

	var body: some View {
		HStack(spacing: .medium3) {
			Image(asset: behavior.icon)

			Text(behavior.description)
				.textStyle(.body2Regular)
				.foregroundColor(.app.gray1)
		}
	}
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
		case .removableByThirdParty:
			return L10n.AccountSettings.Behaviors.removableByThirdParty
		case .removableByAnyone:
			return L10n.AccountSettings.Behaviors.removableByAnyone
		case .freezableByThirdParty:
			return "A third party can freeze this asset in place." // FIXME: Strings ... .freezableByThirdParty
		case .freezableByAnyone:
			return "Anyone can freeze this asset in place." // FIXME: Strings ... .freezableByAnyone
		case .nftDataChangeable:
			return L10n.AccountSettings.Behaviors.nftDataChangeable
		case .nftDataChangeableByAnyone:
			return L10n.AccountSettings.Behaviors.nftDataChangeableByAnyone

		case .informationChangeable:
			return L10n.AccountSettings.Behaviors.informationChangeable
		case .informationChangeableByAnyone:
			return L10n.AccountSettings.Behaviors.informationChangeableByAnyone
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
		case .removableByThirdParty: return AssetResource.removableByThirdParty
		case .removableByAnyone: return AssetResource.removableByAnyone
		case .freezableByThirdParty: return AssetResource.removableByThirdParty // FIXME: icons
		case .freezableByAnyone: return AssetResource.removableByAnyone // FIXME: icons
		case .nftDataChangeable: return AssetResource.nftDataChangeable
		case .nftDataChangeableByAnyone: return AssetResource.nftDataChangeableByAnyone

		case .informationChangeable: return AssetResource.informationChangeable
		case .informationChangeableByAnyone: return AssetResource.informationChangeableByAnyone
		}
	}
}
