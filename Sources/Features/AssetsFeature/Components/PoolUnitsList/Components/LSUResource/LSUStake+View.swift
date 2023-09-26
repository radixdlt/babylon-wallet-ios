import EngineKit
import FeaturePrelude

extension LSUStake.ViewState {
	typealias StakeClaimNFTsViewState = NonEmpty<IdentifiedArrayOf<StakeClaimNFTViewState>>

	public struct StakeClaimNFTViewState: Identifiable, Equatable {
		public let id: NonFungibleGlobalId

		let thumbnail: TokenThumbnail.Content
		let status: StakeClaimNFTStatus
		let tokenAmount: String

		let isSelected: Bool?
	}

	enum StakeClaimNFTStatus: Equatable {
		case unstaking
		case readyToClaim

		fileprivate var localized: String {
			switch self {
			case .unstaking:
				return L10n.Account.PoolUnits.unstaking
			case .readyToClaim:
				return L10n.Account.PoolUnits.readyToClaim
			}
		}

		fileprivate var foregroundColor: Color {
			switch self {
			case .unstaking:
				return .app.gray2
			case .readyToClaim:
				return .app.green1
			}
		}
	}
}

// MARK: - LSUComponentView
extension LSUStake {
	public struct ViewState: Sendable, Equatable, Identifiable {
		public var id: ValidatorAddress

		let validatorNameViewState: ValidatorNameView.ViewState

		let liquidStakeUnit: PoolUnitResourceViewState?
		let stakeClaimNFTs: Loadable<StakeClaimNFTsViewState>?
	}

	public struct View: SwiftUI.View {
		let store: StoreOf<LSUStake>

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: Action.view) { viewStore in
				VStack(alignment: .leading, spacing: .medium1) {
					ValidatorNameView(viewState: viewStore.validatorNameViewState)

					if let liquidStakeUnitViewState = viewStore.liquidStakeUnit {
						liquidStakeUnitView(viewState: liquidStakeUnitViewState)
							.onTapGesture { viewStore.send(.didTap) }
					}

					if let stakeClaimNFTsViewState = viewStore.stakeClaimNFTs {
						stakeClaimNFTsView(viewState: stakeClaimNFTsViewState) {
							viewStore.send(.didTapStakeClaimNFT(withID: $0))
						}
					}
				}
				.padding(.medium1)
				.sheet(
					store: store.scope(
						state: \.$destination,
						action: (/Action.child .. LSUStake.ChildAction.destination).embed
					),
					state: /Destinations.State.details,
					action: Destinations.Action.details,
					content: LSUDetails.View.init
				)
				.task { @MainActor in
					await viewStore.send(.task).finish()
				}
			}
		}

		@ViewBuilder
		private func liquidStakeUnitView(viewState: PoolUnitResourceViewState) -> some SwiftUI.View {
			Text(L10n.Account.PoolUnits.liquidStakeUnits)
				.stakeHeaderStyle

			PoolUnitResourceView(viewState: viewState) {
				VStack(alignment: .leading) {
					Text(viewState.symbol)
						.foregroundColor(.app.gray1)
						.textStyle(.body2HighImportance)

					Text(L10n.Account.PoolUnits.staked)
						.foregroundColor(.app.gray2)
						.textStyle(.body2HighImportance)
				}
			}
			.background(.app.white)
			.borderAround
		}

		private func stakeClaimNFTsView(
			viewState: Loadable<ViewState.StakeClaimNFTsViewState>,
			handleTapGesture: @escaping (ViewState.StakeClaimNFTViewState.ID) -> Void
		) -> some SwiftUI.View {
			VStack(alignment: .leading, spacing: .medium1) {
				Text(L10n.Account.PoolUnits.stakeClaimNFTs)
					.stakeHeaderStyle

				loadable(viewState) { viewState in
					ForEach(viewState) { stakeClaimNFTViewState in
						HStack(spacing: .zero) {
							TokenThumbnail(stakeClaimNFTViewState.thumbnail, size: .smallest)
								.padding(.trailing, .small1)

							Text(stakeClaimNFTViewState.status.localized)
								.foregroundColor(stakeClaimNFTViewState.status.foregroundColor)
								.textStyle(.body2HighImportance)
								.padding(.trailing, .small1)

							Spacer(minLength: 0)

							Text(stakeClaimNFTViewState.tokenAmount)
								.foregroundColor(.app.gray1)
								.textStyle(.secondaryHeader)

							if let isSelected = stakeClaimNFTViewState.isSelected {
								CheckmarkView(appearance: .dark, isChecked: isSelected)
							}
						}
						.borderAround
						.onTapGesture { handleTapGesture(stakeClaimNFTViewState.id) }
					}
				}
			}
		}
	}
}

extension View {
	fileprivate var stakeHeaderStyle: some View {
		foregroundColor(.app.gray2)
			.textStyle(.body2HighImportance)
	}

	fileprivate var borderAround: some View {
		padding(.small2)
			.overlay(
				RoundedRectangle(cornerRadius: .small1)
					.stroke(.app.gray4, lineWidth: 1)
					.padding(.small2 * -1)
			)
	}
}

extension LSUStake.State {
	var viewState: LSUStake.ViewState {
		.init(
			id: stake.validator.address,
			validatorNameViewState: .init(with: stake.validator),
			liquidStakeUnit:
			.init(
				thumbnail: .xrd,
				symbol: Constants.xrdTokenName,
				tokenAmount: xrdRedemptionValue.map { $0.format() },
				isSelected: isStakeSelected
			),

			stakeClaimNFTs: stakeClaimNfts.map { tokens in
				.init(rawValue: .init(uncheckedUniqueElements:
					tokens
						.map { token in
							let status: LSUStake.ViewState.StakeClaimNFTStatus = {
								guard let claimEpoch = token.data.claimEpoch, let epoch = stake.stakeClaimResource?.atLedgerState.epoch else {
									return .unstaking
								}
								return claimEpoch >= epoch ? .readyToClaim : .unstaking
							}()
							return LSUStake.ViewState.StakeClaimNFTViewState(
								id: token.id,
								thumbnail: .xrd,
								status: status,
								tokenAmount: (token.data.claimAmount ?? 0).format(),
								isSelected: nil // self.selectedStakeClaimAssets?.contains(token.id)
							)
						}))
			}.unwrap()
		)
	}
}
