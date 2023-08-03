import FeaturePrelude

extension PoolUnitsList.LSUComponent.State {
	var viewState: PoolUnitsList.LSUComponent.ViewState {
		.init(
			title: "Radostakes",
			liquidStakeUnit: nil,
			stakeClaimNFTs: nil
		)
	}
}

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

extension PoolUnitsList.LSUComponent {
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

// MARK: - PoolUnitsList.LSUComponent.View
extension PoolUnitsList.LSUComponent {
	public struct ViewState: Equatable, Identifiable {
		public var id: String {
			title
		}

		let title: String
		let imageURL: URL = .init(string: "https://i.ibb.co/NsKCTpT/Screenshot-2023-08-02-at-18-18-56.png")!

		let liquidStakeUnit: LiquidStakeUnitViewState?
		let stakeClaimNFTs: NonEmpty<IdentifiedArrayOf<StakeClaimNFTViewState>>?
	}

	public struct View: SwiftUI.View {
		private let store: Store<PoolUnitsList.LSUComponent.ViewState, PoolUnitsList.LSUComponent.ViewAction>

		public init(store: Store<PoolUnitsList.LSUComponent.ViewState, PoolUnitsList.LSUComponent.ViewAction>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store) { viewStore in
				VStack(alignment: .leading, spacing: .medium2) {
					HStack(spacing: .small1) {
						NFTThumbnail(viewStore.imageURL, size: .smallest)
						Text(viewStore.title)
						Spacer()
					}

					if let liquidStakeUnit = viewStore.state.liquidStakeUnit {
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

					if let stakeClaimNFTs = viewStore.stakeClaimNFTs {
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
	}
}

extension PoolUnitsList.ViewState {
	public static var preview: Self {
		.init(
			isExpanded: false,
			lsuComponents: .init(
				[
					.init(
						title: "Radostakes",
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
					),
					.init(
						title: "Radix N Stakes",
						liquidStakeUnit: nil,
						stakeClaimNFTs: .init(
							rawValue: [
								.init(
									id: 0,
									thumbnail: .xrd,
									status: .unstaking,
									tokenAmount: "23,2132.321"
								),
							]
						)
					),
				]
			)
		)
	}
}
