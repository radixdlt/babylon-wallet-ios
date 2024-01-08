import ComposableArchitecture
import SwiftUI
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
				L10n.Account.Staking.unstaking
			case .readyToClaim:
				L10n.Account.Staking.readyToClaim
			}
		}

		fileprivate var foregroundColor: Color {
			switch self {
			case .unstaking:
				.app.gray2
			case .readyToClaim:
				.app.green1
			}
		}
	}
}

// MARK: - LSUComponentView
extension LSUStake {
	public struct ViewState: Sendable, Equatable, Identifiable {
		public var id: ValidatorAddress

		struct Content: Sendable, Equatable {
			let validatorNameViewState: ValidatorNameView.ViewState
			let liquidStakeUnit: PoolUnitResourceViewState?
			let stakeClaimNFTs: StakeClaimNFTsViewState?
		}

		let content: Loadable<Content>
	}

	public struct View: SwiftUI.View {
		let store: StoreOf<LSUStake>

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: Action.view) { viewStore in
				VStack(alignment: .leading, spacing: .medium1) {
					loadable(viewStore.content) { content in
						ValidatorNameView(viewState: content.validatorNameViewState)

						if let liquidStakeUnitViewState = content.liquidStakeUnit {
							liquidStakeUnitView(viewState: liquidStakeUnitViewState)
								.onTapGesture { viewStore.send(.didTap) }
						}

						if let stakeClaimNFTsViewState = content.stakeClaimNFTs {
							stakeClaimNFTsView(viewState: stakeClaimNFTsViewState) {
								viewStore.send(.didTapStakeClaimNFT(withID: $0))
							}
						}
					}
				}
				.padding(.medium1)
			}
			.destinations(with: store)
		}

		@ViewBuilder
		private func liquidStakeUnitView(viewState: PoolUnitResourceViewState) -> some SwiftUI.View {
			Text(L10n.Account.Staking.liquidStakeUnits)
				.stakeHeaderStyle

			PoolUnitResourceView(viewState: viewState) {
				VStack(alignment: .leading) {
					Text(viewState.symbol)
						.foregroundColor(.app.gray1)
						.textStyle(.body2HighImportance)

					Text(L10n.Account.Staking.staked)
						.foregroundColor(.app.gray2)
						.textStyle(.body2HighImportance)
				}
			}
			.background(.app.white)
			.borderAround
		}

		private func stakeClaimNFTsView(
			viewState: ViewState.StakeClaimNFTsViewState,
			handleTapGesture: @escaping (ViewState.StakeClaimNFTViewState.ID) -> Void
		) -> some SwiftUI.View {
			VStack(alignment: .leading, spacing: .medium1) {
				Text(L10n.Account.Staking.stakeClaimNFTs)
					.stakeHeaderStyle

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
		LSUStake.ViewState(id: stake.validatorAddress, content: stakeDetails.map { details in
			LSUStake.ViewState.Content(
				validatorNameViewState: .init(with: details.validator),
				liquidStakeUnit: details.stakeUnitResource.map { resource in
					.init(
						id: resource.resource.resourceAddress, // FIXME: IS THIS CORRECT
						thumbnail: .xrd,
						symbol: Constants.xrdTokenName,
						tokenAmount: details.xrdRedemptionValue.formatted(),
						isSelected: isStakeSelected
					)
				},
				stakeClaimNFTs: details.stakeClaimTokens.flatMap { stakeClaim in
					.init(rawValue:
						stakeClaim.tokens.map { token in
							let status: LSUStake.ViewState.StakeClaimNFTStatus = {
								guard let claimEpoch = token.data?.claimEpoch else {
									return .unstaking
								}

								return claimEpoch <= details.currentEpoch ? .readyToClaim : .unstaking
							}()
							return LSUStake.ViewState.StakeClaimNFTViewState(
								id: token.id,
								thumbnail: .xrd,
								status: status,
								tokenAmount: (token.data?.claimAmount ?? 0).formatted(),
								isSelected: self.selectedStakeClaimAssets?.contains(token)
							)
						}.asIdentifiable()
					)
				}
			)
		})
	}
}

private extension StoreOf<LSUStake> {
	var destination: PresentationStoreOf<LSUStake.Destination> {
		func scopeState(state: State) -> PresentationState<LSUStake.Destination.State> {
			state.$destination
		}
		return scope(state: scopeState, action: Action.destination)
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<LSUStake>) -> some View {
		let destinationStore = store.destination
		return lsuDetails(with: destinationStore)
			.stakeClaimNFTDetails(with: destinationStore)
	}

	private func lsuDetails(with destinationStore: PresentationStoreOf<LSUStake.Destination>) -> some View {
		sheet(
			store: destinationStore,
			state: /LSUStake.Destination.State.details,
			action: LSUStake.Destination.Action.details,
			content: { LSUDetails.View(store: $0) }
		)
	}

	private func stakeClaimNFTDetails(with destinationStore: PresentationStoreOf<LSUStake.Destination>) -> some View {
		sheet(
			store: destinationStore,
			state: /LSUStake.Destination.State.stakeClaimDetails,
			action: LSUStake.Destination.Action.stakeClaimDetails,
			content: { NonFungibleTokenDetails.View(store: $0) }
		)
	}
}
