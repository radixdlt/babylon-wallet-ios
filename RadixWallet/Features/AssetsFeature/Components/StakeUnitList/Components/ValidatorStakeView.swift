import ComposableArchitecture
import SwiftUI

// MARK: - ValidatorStakeView
struct ValidatorStakeView: View {
	public struct ViewState: Sendable, Hashable, Identifiable {
		public var id: ValidatorAddress

		struct Content: Sendable, Hashable {
			let validatorNameViewState: ValidatorHeaderView.ViewState
			var liquidStakeUnit: LiquidStakeUnitView.ViewState?
			var stakeClaimNFTs: StakeClaimNFTSView.ViewState?
		}

		var content: Loadable<Content>
	}

	let viewState: ViewState
	@State var isExpanded: Bool = false
	var onLiquidStakeUnitTapped: () -> Void
	var onStakeClaimTokenTapped: (OnLedgerEntitiesClient.StakeClaim) -> Void
	var onClaimAllStakeClaimsTapped: () -> Void

	public var body: some SwiftUI.View {
		loadable(viewState.content) { content in
			ValidatorHeaderView(viewState: content.validatorNameViewState)
				.contentShape(Rectangle())
				.rowStyle()
				.padding(.medium1)
				.onTapGesture {
					isExpanded.toggle()
				}

			if isExpanded {
				if let liquidStakeUnitViewState = content.liquidStakeUnit {
					liquidStakeUnitView(viewState: liquidStakeUnitViewState)
						.rowStyle()
						.onTapGesture { onLiquidStakeUnitTapped() }
				}

				if let stakeClaimNFTsViewState = content.stakeClaimNFTs {
					stakeClaimNFTsView(
						viewState: stakeClaimNFTsViewState,
						handleTapGesture: onStakeClaimTokenTapped,
						onClaimAllTapped: onClaimAllStakeClaimsTapped
					)
					.rowStyle()
				}
			}
		}
		.background(.app.white)
	}

	@ViewBuilder
	private func liquidStakeUnitView(viewState: LiquidStakeUnitView.ViewState) -> some SwiftUI.View {
		VStack(spacing: .zero) {
			Divider()
				.frame(height: .small3)
				.overlay(.app.gray5)

			LiquidStakeUnitView(viewState: viewState)
				.padding(.medium1)
		}
		.contentShape(Rectangle())
	}

	private func stakeClaimNFTsView(
		viewState: StakeClaimNFTSView.ViewState,
		handleTapGesture: @escaping (OnLedgerEntitiesClient.StakeClaim) -> Void,
		onClaimAllTapped: @escaping () -> Void
	) -> some SwiftUI.View {
		VStack(spacing: .zero) {
			Divider()
				.frame(height: .small3)
				.overlay(.app.gray5)

			StakeClaimNFTSView(viewState: viewState, onTap: handleTapGesture, onClaimAllTapped: onClaimAllTapped)
				.padding(.medium1)
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
