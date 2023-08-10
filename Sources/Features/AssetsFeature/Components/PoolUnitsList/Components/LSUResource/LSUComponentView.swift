import EngineKit
import FeaturePrelude

extension LSUComponentView {
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
struct LSUComponentView: View {
	typealias StakeClaimNFTsViewState = NonEmpty<IdentifiedArrayOf<StakeClaimNFTViewState>>

	public struct ViewState: Equatable, Identifiable {
		public var id: ValidatorAddress

		let title: String
		let imageURL: URL?

		let liquidStakeUnit: PoolUnitResourceViewState?
		let stakeClaimNFTs: StakeClaimNFTsViewState?
	}

	let viewState: ViewState

	var body: some View {
		VStack(alignment: .leading, spacing: .medium1) {
			HStack(spacing: .small1) {
				NFTThumbnail(viewState.imageURL, size: .smallest)
				Text(viewState.title)
				Spacer()
			}

			if let liquidStakeUnitViewState = viewState.liquidStakeUnit {
				liquidStakeUnitView(viewState: liquidStakeUnitViewState)
			}

			if let stakeClaimNFTsViewState = viewState.stakeClaimNFTs {
				stakeClaimNFTsView(viewState: stakeClaimNFTsViewState)
			}
		}
		.padding(.medium1)
	}

	@ViewBuilder
	private func liquidStakeUnitView(viewState: PoolUnitResourceViewState) -> some View {
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

	private func stakeClaimNFTsView(viewState: StakeClaimNFTsViewState) -> some View {
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
