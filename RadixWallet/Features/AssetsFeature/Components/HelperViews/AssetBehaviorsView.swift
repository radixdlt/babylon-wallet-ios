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
					ForEach(filteredBehaviors, id: \.self) { behavior in
						AssetBehaviorRow(behavior: behavior, isXRD: isXRD)
					}
				}

				InfoButton(.behaviors, label: "What are behaviors?") // FIXME: Strings
			}
			.transition(.opacity.combined(with: .scale(scale: 0.8)))
		}
	}

	private var filteredBehaviors: [AssetBehavior] {
		behaviors.filter {
			!(isXRD && $0 == .informationChangeable)
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
			L10n.AssetDetails.Behaviors.simpleAsset
		case .supplyIncreasable:
			L10n.AssetDetails.Behaviors.supplyIncreasable
		case .supplyDecreasable:
			L10n.AssetDetails.Behaviors.supplyDecreasable
		case .supplyIncreasableByAnyone:
			L10n.AssetDetails.Behaviors.supplyIncreasableByAnyone
		case .supplyDecreasableByAnyone:
			L10n.AssetDetails.Behaviors.supplyDecreasableByAnyone
		case .supplyFlexible:
			if isXRD {
				L10n.AssetDetails.Behaviors.supplyFlexibleXrd
			} else {
				L10n.AssetDetails.Behaviors.supplyFlexible
			}
		case .supplyFlexibleByAnyone:
			L10n.AssetDetails.Behaviors.supplyFlexibleByAnyone
		case .movementRestricted:
			L10n.AssetDetails.Behaviors.movementRestricted
		case .movementRestrictableInFuture:
			L10n.AssetDetails.Behaviors.movementRestrictableInFuture
		case .movementRestrictableInFutureByAnyone:
			L10n.AssetDetails.Behaviors.movementRestrictableInFutureByAnyone
		case .removableByThirdParty:
			L10n.AssetDetails.Behaviors.removableByThirdParty
		case .removableByAnyone:
			L10n.AssetDetails.Behaviors.removableByAnyone
		case .freezableByThirdParty:
			L10n.AssetDetails.Behaviors.freezableByThirdParty
		case .freezableByAnyone:
			L10n.AssetDetails.Behaviors.freezableByAnyone
		case .nftDataChangeable:
			L10n.AssetDetails.Behaviors.nftDataChangeable
		case .nftDataChangeableByAnyone:
			L10n.AssetDetails.Behaviors.nftDataChangeableByAnyone
		case .informationChangeable:
			L10n.AssetDetails.Behaviors.informationChangeable
		case .informationChangeableByAnyone:
			L10n.AssetDetails.Behaviors.informationChangeableByAnyone
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
		case .freezableByThirdParty: AssetResource.freezableByThirdParty
		case .freezableByAnyone: AssetResource.freezableByAnyone
		case .nftDataChangeable: AssetResource.nftDataChangeable
		case .nftDataChangeableByAnyone: AssetResource.nftDataChangeableByAnyone
		case .informationChangeable: AssetResource.informationChangeable
		case .informationChangeableByAnyone: AssetResource.informationChangeableByAnyone
		}
	}
}
