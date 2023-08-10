import EngineKit
import FeaturePrelude

extension LSUComponent.ViewState {
	typealias StakeClaimNFTsViewState = NonEmpty<IdentifiedArrayOf<StakeClaimNFTViewState>>

	struct StakeClaimNFTViewState: Identifiable, Equatable {
		let id: Int

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
extension LSUComponent {
	public struct ViewState: Sendable, Equatable, Identifiable {
		public var id: Int

		let title: String
		let imageURL: URL?

		let liquidStakeUnit: PoolUnitResourceViewState?
		let stakeClaimNFTs: StakeClaimNFTsViewState?
	}

	public struct View: SwiftUI.View {
		let store: StoreOf<LSUComponent>

		public var body: some SwiftUI.View {
			WithViewStore(
				store,
				observe: \.viewState,
				send: Action.view
			) { viewStore in
				VStack(alignment: .leading, spacing: .medium1) {
					HStack(spacing: .small1) {
						NFTThumbnail(viewStore.imageURL, size: .smallest)
						Text(viewStore.title)
						Spacer()
					}

					if let liquidStakeUnitViewState = viewStore.liquidStakeUnit {
						liquidStakeUnitView(viewState: liquidStakeUnitViewState)
							.onTapGesture {
								viewStore.send(.didTap)
							}
					}

					if let stakeClaimNFTsViewState = viewStore.stakeClaimNFTs {
						stakeClaimNFTsView(viewState: stakeClaimNFTsViewState)
					}
				}
				.padding(.medium1)
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

extension LSUComponent.State {
	var viewState: LSUComponent.ViewState {
		.init(
			id: 0,
			title: "Radostakes",
			imageURL: .init(string: "https://i.ibb.co/NsKCTpT/Screenshot-2023-08-02-at-18-18-56.png")!,
			liquidStakeUnit: .init(
				thumbnail: .xrd,
				symbol: "XRD",
				tokenAmount: "2.0129822"
			),
			stakeClaimNFTs: .init(
				rawValue: [
					.init(
						id: 0,
						thumbnail: .xrd,
						status: .unstaking,
						tokenAmount: "450.0"
					),
					.init(
						id: 1,
						thumbnail: .xrd,
						status: .unstaking,
						tokenAmount: "1,250.0"
					),
					.init(
						id: 2,
						thumbnail: .xrd,
						status: .readyToClaim,
						tokenAmount: "1,200.0"
					),
				]
			)
		)
	}
}
