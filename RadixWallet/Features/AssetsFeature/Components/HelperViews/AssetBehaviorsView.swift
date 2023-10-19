import ComposableArchitecture
import SwiftUI

// MARK: - AssetBehaviorsView
struct AssetBehaviorsView: View {
	let behaviors: [AssetBehavior]
	let isXRD: Bool

	var body: some View {
		if !behaviors.isEmpty {
			Group {
				Text(L10n.AssetDetails.behavior)
					.textStyle(.body1Regular)
					.foregroundColor(.app.gray2)

				VStack(alignment: .leading, spacing: .small1) {
					ForEach(behaviors, id: \.self) { behavior in
						AssetBehaviorRow(behavior: behavior, isXRD: isXRD)
					}
				}
			}
			.transition(.opacity.combined(with: .scale(scale: 0.8)))
		}
	}
}

// MARK: - AssetBehaviorRow
struct AssetBehaviorRow: View {
	let behavior: AssetBehavior
	let isXRD: Bool

	var body: some View {
		HStack(spacing: .medium3) {
			Image(asset: behavior.icon)

			Text(behavior.text(isXRD: isXRD))
				.lineLimit(2)
				.textStyle(.body2Regular)
				.foregroundColor(.app.gray1)
		}
	}
}

extension AssetBehavior {
	public func text(isXRD: Bool) -> String {
		switch self {
		case .simpleAsset:
			L10n.AccountSettings.Behaviors.simpleAsset
		case .supplyIncreasable:
			L10n.AccountSettings.Behaviors.supplyIncreasable
		case .supplyDecreasable:
			L10n.AccountSettings.Behaviors.supplyDecreasable
		case .supplyIncreasableByAnyone:
			L10n.AccountSettings.Behaviors.supplyIncreasableByAnyone
		case .supplyDecreasableByAnyone:
			L10n.AccountSettings.Behaviors.supplyDecreasableByAnyone
		case .supplyFlexible:
			if isXRD {
				L10n.AccountSettings.Behaviors.supplyFlexibleXrd
			} else {
				L10n.AccountSettings.Behaviors.supplyFlexible
			}
		case .supplyFlexibleByAnyone:
			L10n.AccountSettings.Behaviors.supplyFlexibleByAnyone
		case .movementRestricted:
			L10n.AccountSettings.Behaviors.movementRestricted
		case .movementRestrictableInFuture:
			L10n.AccountSettings.Behaviors.movementRestrictableInFuture
		case .movementRestrictableInFutureByAnyone:
			L10n.AccountSettings.Behaviors.movementRestrictableInFutureByAnyone
		case .removableByThirdParty:
			L10n.AccountSettings.Behaviors.removableByThirdParty
		case .removableByAnyone:
			L10n.AccountSettings.Behaviors.removableByAnyone
		case .freezableByThirdParty:
			"A third party can freeze this asset in place." // FIXME: Strings ... .freezableByThirdParty
		case .freezableByAnyone:
			"Anyone can freeze this asset in place." // FIXME: Strings ... .freezableByAnyone
		case .nftDataChangeable:
			L10n.AccountSettings.Behaviors.nftDataChangeable
		case .nftDataChangeableByAnyone:
			L10n.AccountSettings.Behaviors.nftDataChangeableByAnyone
		case .informationChangeable:
			L10n.AccountSettings.Behaviors.informationChangeable
		case .informationChangeableByAnyone:
			L10n.AccountSettings.Behaviors.informationChangeableByAnyone
		}
	}

	public var icon: ImageAsset {
		switch self {
		case .simpleAsset: AssetResource.simpleAsset
		case .supplyIncreasable: AssetResource.supplyIncreasable
		case .supplyDecreasable: AssetResource.supplyDecreasable
		case .supplyIncreasableByAnyone: AssetResource.supplyIncreasableByAnyone
		case .supplyDecreasableByAnyone: AssetResource.supplyDecreasableByAnyone
		case .supplyFlexible: AssetResource.supplyFlexible
		case .supplyFlexibleByAnyone: AssetResource.supplyFlexibleByAnyone
		case .movementRestrictableInFuture: AssetResource.movementRestrictableInFuture
		case .movementRestrictableInFutureByAnyone: AssetResource.movementRestrictableInFutureByAnyone
		case .movementRestricted: AssetResource.movementRestricted
		case .removableByThirdParty: AssetResource.removableByThirdParty
		case .removableByAnyone: AssetResource.removableByAnyone
		case .freezableByThirdParty: AssetResource.removableByThirdParty // FIXME: icons
		case .freezableByAnyone: AssetResource.removableByAnyone // FIXME: icons
		case .nftDataChangeable: AssetResource.nftDataChangeable
		case .nftDataChangeableByAnyone: AssetResource.nftDataChangeableByAnyone
		case .informationChangeable: AssetResource.informationChangeable
		case .informationChangeableByAnyone: AssetResource.informationChangeableByAnyone
		}
	}
}
