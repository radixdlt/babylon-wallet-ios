import ComposableArchitecture
import SwiftUI

// MARK: - ValidatorStakeView
struct ValidatorStakeView: View {
	struct ViewState: Sendable, Hashable, Identifiable {
		var id: ValidatorAddress {
			stakeDetails.id
		}

		let stakeDetails: OnLedgerEntitiesClient.OwnedStakeDetails

		let validatorNameViewState: ValidatorHeaderView.ViewState
		var liquidStakeUnit: LiquidStakeUnit?
		var stakeClaimResource: KnownResourceBalance.StakeClaimNFT?

		struct LiquidStakeUnit: Sendable, Hashable {
			let lsu: ResourceBalance.ViewState.LiquidStakeUnit
			var isSelected: Bool?
		}
	}

	let viewState: ViewState
	@State var isExpanded: Bool = false
	let onLiquidStakeUnitTapped: () -> Void
	let onStakeClaimTokenTapped: (OnLedgerEntitiesClient.StakeClaim) -> Void
	let onClaimAllStakeClaimsTapped: () -> Void

	var body: some SwiftUI.View {
		Button {
			isExpanded.toggle()
		} label: {
			ValidatorHeaderView(viewState: viewState.validatorNameViewState)
				.contentShape(Rectangle())
				.padding(.vertical, .large3)
				.padding(.horizontal, .medium1)
		}
		.buttonStyle(.borderless)
		.rowStyle()

		if isExpanded {
			if let liquidStakeUnitViewState = viewState.liquidStakeUnit {
				liquidStakeUnitView(viewState: liquidStakeUnitViewState, action: onLiquidStakeUnitTapped)
					.rowStyle()
			}

			if let stakeClaimNFTsViewState = viewState.stakeClaimResource {
				stakeClaimNFTsView(
					viewState: stakeClaimNFTsViewState,
					onTap: onStakeClaimTokenTapped,
					onClaimAllTapped: onClaimAllStakeClaimsTapped
				)
				.rowStyle()
			}
		}
	}

	@ViewBuilder
	private func liquidStakeUnitView(viewState: ViewState.LiquidStakeUnit, action: @escaping () -> Void) -> some SwiftUI.View {
		VStack(spacing: .zero) {
			AssetListSeparator()
			ResourceBalanceButton(.liquidStakeUnit(viewState.lsu), appearance: .assetList, isSelected: viewState.isSelected, onTap: action)
		}
	}

	private func stakeClaimNFTsView(
		viewState: KnownResourceBalance.StakeClaimNFT,
		onTap: @escaping (OnLedgerEntitiesClient.StakeClaim) -> Void,
		onClaimAllTapped: @escaping () -> Void
	) -> some SwiftUI.View {
		VStack(spacing: .zero) {
			AssetListSeparator()
			ResourceBalanceView.StakeClaimNFT(
				viewState: viewState,
				appearance: .standalone,
				compact: false,
				onTap: onTap,
				onClaimAllTapped: onClaimAllTapped
			)
			.padding(.medium3)
		}
	}
}
