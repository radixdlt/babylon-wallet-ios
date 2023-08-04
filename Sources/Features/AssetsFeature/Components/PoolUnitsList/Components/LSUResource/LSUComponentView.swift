import FeaturePrelude

extension LSUComponentView {
	struct LiquidStakeUnitViewState: Identifiable, Equatable {
		var id: String {
			symbol
		}

		let thumbnail: TokenThumbnail.Content
		let symbol: String
		let tokenAmount: String
	}

	struct StakeClaimNFTViewState: Identifiable, Equatable {
		let id: Int

		let thumbnail: TokenThumbnail.Content
		let status: StakeClaimNFTStatus
		let tokenAmount: String
	}

	enum StakeClaimNFTStatus: Equatable {
		case unstaking
		case readyToClaim

		// FIXME: Localize
		var localized: String {
			switch self {
			case .unstaking:
				return "Unstaking"
			case .readyToClaim:
				return "Ready to Claim"
			}
		}
	}
}

// MARK: - LSUComponentView
struct LSUComponentView: View {
	typealias StakeClaimNFTsViewState = NonEmpty<IdentifiedArrayOf<StakeClaimNFTViewState>>

	public struct ViewState: Equatable, Identifiable {
		public var id: Int

		let title: String
		let imageURL: URL

		let liquidStakeUnit: LiquidStakeUnitViewState?
		let stakeClaimNFTs: StakeClaimNFTsViewState?
	}

	let viewState: ViewState

	var body: some View {
		VStack(alignment: .leading, spacing: .medium2) {
			HStack(spacing: .small1) {
				NFTThumbnail(viewState.imageURL, size: .smallest)
				Text(viewState.title)
				Spacer()
			}

			if let liquidStakeUnitViewState = viewState.liquidStakeUnit {
				liquidStakeUnitView(with: liquidStakeUnitViewState)
			}

			if let stakeClaimNFTsViewState = viewState.stakeClaimNFTs {
				stakeClaimNFTsView(with: stakeClaimNFTsViewState)
			}
		}
		.padding(.medium1)
	}

	private func liquidStakeUnitView(with viewState: LiquidStakeUnitViewState) -> some View {
		Group {
			// FIXME: Localize
			Text("LIQUID STAKE UNITS")
				.stakeHeaderStyle

			HStack {
				HStack(spacing: .small1) {
					TokenThumbnail(
						viewState.thumbnail,
						size: .small
					)

					HStack {
						VStack(alignment: .leading) {
							Text(viewState.symbol)
								.foregroundColor(.app.gray1)
								.textStyle(.body2HighImportance)
							// FIXME: Localize
							Text("Staked")
								.foregroundColor(.app.gray2)
								.textStyle(.body2HighImportance)
						}

						Spacer()

						Text(viewState.tokenAmount)
							.foregroundColor(.app.gray1)
							.textStyle(.secondaryHeader)
					}
				}
			}
			.borderAround
		}
	}

	private func stakeClaimNFTsView(with viewState: StakeClaimNFTsViewState) -> some View {
		VStack(alignment: .leading, spacing: .medium1) {
			// FIXME: Localize
			Text("STAKE CLAIM NFTS")
				.stakeHeaderStyle

			ForEach(viewState) { stakeClaimNFT in
				HStack {
					HStack(spacing: .small1) {
						TokenThumbnail(
							stakeClaimNFT.thumbnail,
							size: .smallest
						)

						Text(stakeClaimNFT.status.localized)
							.foregroundColor(.app.gray2)
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
