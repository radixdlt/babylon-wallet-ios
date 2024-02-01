import ComposableArchitecture
import SwiftUI

// MARK: - ValidatorStakeView
struct ValidatorStakeView: View {
	public struct ViewState: Sendable, Hashable, Identifiable {
		public var id: ValidatorAddress {
			stakeDetails.id
		}

		let stakeDetails: OnLedgerEntitiesClient.OwnedStakeDetails

		let validatorNameViewState: ValidatorHeaderView.ViewState
		var liquidStakeUnit: LiquidStakeUnitView.ViewState?
		var stakeClaimResource: StakeClaimResourceView.ViewState?
	}

	let viewState: ViewState
	@State var isExpanded: Bool = false
	let onLiquidStakeUnitTapped: () -> Void
	let onStakeClaimTokenTapped: (OnLedgerEntitiesClient.StakeClaim) -> Void
	let onClaimAllStakeClaimsTapped: () -> Void

	public var body: some SwiftUI.View {
		Button {
			isExpanded.toggle()
		} label: {
			ValidatorHeaderView(viewState: viewState.validatorNameViewState)
				.contentShape(Rectangle())
				.padding(.vertical, .medium3)
				.padding(.horizontal, .small1)
				.rowStyle()
		}
		.buttonStyle(.borderless)

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
	private func liquidStakeUnitView(viewState: LiquidStakeUnitView.ViewState, action: @escaping () -> Void) -> some SwiftUI.View {
		VStack(spacing: .zero) {
			Divider()
				.frame(height: .small3)
				.overlay(.app.gray5)

			LiquidStakeUnitView(viewState: viewState, background: .app.white, onTap: action)
		}
	}

	private func stakeClaimNFTsView(
		viewState: StakeClaimResourceView.ViewState,
		onTap: @escaping (OnLedgerEntitiesClient.StakeClaim) -> Void,
		onClaimAllTapped: @escaping () -> Void
	) -> some SwiftUI.View {
		VStack(spacing: .zero) {
			Divider()
				.frame(height: .small3)
				.overlay(.app.gray5)

			StakeClaimResourceView(
				viewState: viewState,
				background: .app.white,
				onTap: onTap,
				onClaimAllTapped: onClaimAllTapped
			)
		}
	}
}

extension View {
	private var stakeHeaderStyle: some View {
		foregroundColor(.app.gray2)
			.textStyle(.body2HighImportance)
	}

	private var borderAround: some View {
		padding(.small2)
			.overlay(
				RoundedRectangle(cornerRadius: .small1)
					.stroke(.app.gray4, lineWidth: 1)
					.padding(.small2 * -1)
			)
	}
}
