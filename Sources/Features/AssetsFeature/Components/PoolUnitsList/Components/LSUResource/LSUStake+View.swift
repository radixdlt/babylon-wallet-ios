import EngineKit
import FeaturePrelude

extension LSUStake.ViewState {
	typealias StakeClaimNFTsViewState = NonEmpty<IdentifiedArrayOf<StakeClaimNFTViewState>>

	struct StakeClaimNFTViewState: Identifiable, Equatable {
		let id: NonFungibleGlobalId

		let thumbnail: TokenThumbnail.Content
		let status: StakeClaimNFTStatus
		let tokenAmount: String
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

		let validatorNameViewState: ValidatorNameViewState

		let liquidStakeUnit: PoolUnitResourceViewState?
		let stakeClaimNFTs: StakeClaimNFTsViewState?
	}

	public struct View: SwiftUI.View {
		let store: StoreOf<LSUStake>

		public var body: some SwiftUI.View {
			WithViewStore(
				store,
				observe: \.viewState,
				send: Action.view
			) { viewStore in
				VStack(alignment: .leading, spacing: .medium1) {
					LSUMaker.makeValidatorNameView(viewState: viewStore.validatorNameViewState)

					if let liquidStakeUnitViewState = viewStore.liquidStakeUnit {
						liquidStakeUnitView(viewState: liquidStakeUnitViewState)
							.onTapGesture { viewStore.send(.didTap) }
					}

					if let stakeClaimNFTsViewState = viewStore.stakeClaimNFTs {
						stakeClaimNFTsView(viewState: stakeClaimNFTsViewState)
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

		private func stakeClaimNFTsView(viewState: ViewState.StakeClaimNFTsViewState) -> some SwiftUI.View {
			VStack(alignment: .leading, spacing: .medium1) {
				Text(L10n.Account.PoolUnits.stakeClaimNFTs)
					.stakeHeaderStyle

				ForEach(viewState) { stakeClaimNFT in
					HStack {
						HStack(spacing: .small1) {
							TokenThumbnail(
								stakeClaimNFT.thumbnail,
								size: .smallest
							)

							Text(stakeClaimNFT.status.localized)
								.foregroundColor(stakeClaimNFT.status.foregroundColor)
								.textStyle(.body2HighImportance)
						}

						Spacer()

						Text(stakeClaimNFT.tokenAmount)
							.foregroundColor(.app.gray1)
							.textStyle(.secondaryHeader)
					}
					.borderAround
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
			liquidStakeUnit: stake.xrdRedemptionValue
				.map {
					.init(
						thumbnail: .xrd,
						symbol: Constants.xrdTokenName,
						tokenAmount: $0.format()
					)
				},
			stakeClaimNFTs: .init(
				rawValue: stake.stakeClaimResource
					.map { claimNFT in
						.init(
							uncheckedUniqueElements: claimNFT.tokens
								.map { token in
									LSUStake.ViewState.StakeClaimNFTViewState(
										id: token.id,
										thumbnail: .xrd,
										status: token.canBeClaimed ? .readyToClaim : .unstaking,
										tokenAmount: (token.stakeClaimAmount ?? 0).format()
									)
								}
						)
					} ?? []
			)
		)
	}
}
