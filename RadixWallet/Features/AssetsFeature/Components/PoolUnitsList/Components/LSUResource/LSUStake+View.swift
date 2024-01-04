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
			let liquidStakeUnit: LiquidStakeUnitView.ViewState?
			let stakeClaimNFTs: StakeClaimNFTSView.ViewState?
		}

		let content: Loadable<Content>
		let isExpanded: Bool
	}

	public struct View: SwiftUI.View {
		let store: StoreOf<LSUStake>

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: Action.view) { viewStore in
				Section {
					loadable(viewStore.content) { content in
						ValidatorNameView(viewState: content.validatorNameViewState)
							.onTapGesture {
								viewStore.send(.expandToggled)
							}
							.rowStyle()
							.padding(.medium1)

						if viewStore.isExpanded {
							if let liquidStakeUnitViewState = content.liquidStakeUnit {
								liquidStakeUnitView(viewState: liquidStakeUnitViewState)
									.onTapGesture { viewStore.send(.didTap) }
									.rowStyle()
							}

							if let stakeClaimNFTsViewState = content.stakeClaimNFTs {
								stakeClaimNFTsView(viewState: stakeClaimNFTsViewState) {
									viewStore.send(.didTapStakeClaimNFT(withID: $0))
								}
								.rowStyle()
							}
						}
					}
					.background(.app.white)
				}
			}
			.destinations(with: store)
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
		}

		private func stakeClaimNFTsView(
			viewState: StakeClaimNFTSView.ViewState,
			handleTapGesture: @escaping (NonFungibleGlobalId) -> Void
		) -> some SwiftUI.View {
			VStack(spacing: .zero) {
				Divider()
					.frame(height: .small3)
					.overlay(.app.gray5)

				StakeClaimNFTSView(viewState: viewState, onTap: handleTapGesture)
					.padding(.medium1)
			}
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

extension LSUStake.State {
	var viewState: LSUStake.ViewState {
		LSUStake.ViewState(
			id: stake.validatorAddress,
			content: stakeDetails.map { details in
				LSUStake.ViewState.Content(
					validatorNameViewState: .init(with: details.validator, stakedAmount: details.xrdRedemptionValue),
					liquidStakeUnit: details.stakeUnitResource.map { resource in
						LiquidStakeUnitView.ViewState(resource: resource.resource, worth: details.xrdRedemptionValue)
					},
					stakeClaimNFTs: details.stakeClaimTokens.flatMap { stakeClaim in
						StakeClaimNFTSView.ViewState(
							resource: stakeClaim.resource,
							sections: {
								var unstakingTokens: StakeClaimNFTSView.StakeClaims = .init()
								var readyToClaimTokens: StakeClaimNFTSView.StakeClaims = .init()
								for token in stakeClaim.tokens {
									if let claimEpoch = token.data?.claimEpoch, claimEpoch <= details.currentEpoch {
										readyToClaimTokens.append(.init(id: token.id, worth: token.data?.claimAmount ?? 0))
									} else {
										unstakingTokens.append(.init(id: token.id, worth: token.data?.claimAmount ?? 0))
									}
								}
								var sections: IdentifiedArrayOf<StakeClaimNFTSView.Section> = []
								if !unstakingTokens.isEmpty {
									sections.append(.unstaking(unstakingTokens))
								}

								if !readyToClaimTokens.isEmpty {
									sections.append(.readyToBeClaimed(readyToClaimTokens))
								}
								return sections
							}()
						)
					}
				)
			},
			isExpanded: isExpanded
		)
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
