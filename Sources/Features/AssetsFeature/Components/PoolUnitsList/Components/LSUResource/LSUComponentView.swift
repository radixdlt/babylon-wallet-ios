import FeaturePrelude

// MARK: - StakeClaimNFTStatus
enum StakeClaimNFTStatus: Equatable {
	case unstaking
	case readyToClaim

	var localized: String {
		switch self {
		case .unstaking:
			return "Unstaking"
		case .readyToClaim:
			return "Ready to Claim"
		}
	}
}

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
}

// MARK: - LSUComponentView
struct LSUComponentView: View {
	public struct ViewState: Equatable, Identifiable {
		public var id: String {
			title
		}

		let title: String
		let imageURL: URL = .init(string: "https://i.ibb.co/NsKCTpT/Screenshot-2023-08-02-at-18-18-56.png")!

		let liquidStakeUnit: LiquidStakeUnitViewState?
		let stakeClaimNFTs: NonEmpty<IdentifiedArrayOf<StakeClaimNFTViewState>>?
	}

	let viewState: ViewState

	var body: some View {
		VStack(alignment: .leading, spacing: .medium2) {
			HStack(spacing: .small1) {
				NFTThumbnail(viewState.imageURL, size: .smallest)
				Text(viewState.title)
				Spacer()
			}

			if let liquidStakeUnit = viewState.liquidStakeUnit {
				Text("LIQUID STAKE UNITS")
					.foregroundColor(.app.gray2)
					.textStyle(.body2HighImportance)

				HStack {
					HStack(spacing: .small1) {
						TokenThumbnail(
							liquidStakeUnit.thumbnail,
							size: .small
						)

						HStack {
							VStack(alignment: .leading) {
								Text(liquidStakeUnit.symbol)
									.foregroundColor(.app.gray1)
									.textStyle(.body2HighImportance)
								Text("Staked")
									.foregroundColor(.app.gray2)
									.textStyle(.body2HighImportance)
							}

							Spacer()

							Text(liquidStakeUnit.tokenAmount)
								.foregroundColor(.app.gray1)
								.textStyle(.secondaryHeader)
						}
					}
				}
				.padding(.small2)
				.overlay(
					RoundedRectangle(cornerRadius: .small1)
						.stroke(.app.gray4, lineWidth: 1)
						.padding(.small2 * -1)
				)
			}

			if let stakeClaimNFTs = viewState.stakeClaimNFTs {
				VStack(alignment: .leading, spacing: .medium1) {
					Text("STAKE CLAIM NFTS")
						.foregroundColor(.app.gray2)
						.textStyle(.body2HighImportance)

					ForEach(stakeClaimNFTs) { stakeClaimNFT in
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
						.padding(.small2)
						.overlay(
							RoundedRectangle(cornerRadius: .small1)
								.stroke(.app.gray4, lineWidth: 1)
								.padding(.small2 * -1)
						)
					}
				}
			}
		}
		.padding(.medium1)
	}
}

extension PoolUnitsList.State {
	public static var preview: Self {
		.init(
			lsuResource: .init(
				isExpanded: false,
				components: []
			)
		)
	}
}
