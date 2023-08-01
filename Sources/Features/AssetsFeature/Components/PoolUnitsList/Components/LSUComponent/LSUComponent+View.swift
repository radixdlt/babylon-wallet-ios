import FeaturePrelude

extension PoolUnitsList.LSUComponent.State {
	var viewState: PoolUnitsList.LSUComponent.ViewState {
		.init(
			title: "Radostakes",
			liquidStakeUnits: .init(),
			stakeClaimNFTs: nil
		)
	}
}

extension PoolUnitsList.ViewState {
	public static var preview: Self {
		.init(
			lsuComponents: .init(
				[
					.init(
						title: "Radostakes",
						liquidStakeUnits: [
							.init(
								thumbnail: .xrd,
								symbol: "XRD",
								tokenAmount: "2.0129822",
								stakedAmmount: "$138,021.03"
							),
							.init(
								thumbnail: .unknown,
								symbol: "???",
								tokenAmount: "4.434255",
								stakedAmmount: "$78,371.20"
							),
						],
						stakeClaimNFTs: .init(
							rawValue: [
								.init(
									id: 0,
									thumbnail: .xrd,
									kind: .unstaking,
									tokenAmount: "450.0"
								),
								.init(
									id: 1,
									thumbnail: .xrd,
									kind: .unstaking,
									tokenAmount: "1,250.0"
								),
								.init(
									id: 2,
									thumbnail: .xrd,
									kind: .readyToClaim,
									tokenAmount: "1,200.0"
								),
							]
						)
					),
					.init(
						title: "Radix N Stakes",
						liquidStakeUnits: [
							.init(
								thumbnail: .xrd,
								symbol: "XRD",
								tokenAmount: "332.231578",
								stakedAmmount: "$863.21"
							),
						],
						stakeClaimNFTs: nil
					),
				]
			)
		)
	}
}

// MARK: - StakeClaimNFTKind
enum StakeClaimNFTKind: Equatable {
	case unstaking
	case readyToClaim
}

extension PoolUnitsList.LSUComponent {
	struct LiquidStakeUnitViewState: Identifiable, Equatable {
		var id: String {
			symbol
		}

		let thumbnail: TokenThumbnail.Content
		let symbol: String
		let tokenAmount: String

		let stakedAmmount: String
	}

	struct StakeClaimNFTViewState: Identifiable, Equatable {
		let id: Int

		let thumbnail: TokenThumbnail.Content
		let kind: StakeClaimNFTKind
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
		let imageURL: URL = .init(string: "www.wp.pl")!

		let liquidStakeUnits: IdentifiedArrayOf<LiquidStakeUnitViewState>
		let stakeClaimNFTs: NonEmpty<IdentifiedArrayOf<StakeClaimNFTViewState>>?
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: Store<PoolUnitsList.LSUComponent.ViewState, PoolUnitsList.LSUComponent.ViewAction>

		public init(store: Store<PoolUnitsList.LSUComponent.ViewState, PoolUnitsList.LSUComponent.ViewAction>) {
			self.store = store
		}

		// style...
		public var body: some SwiftUI.View {
			WithViewStore(store) { viewStore in
				VStack(spacing: .medium1) {
					Text(viewStore.title)
					// localize
					Text("LIQUID STAKE UNITS")

					ForEach(viewStore.liquidStakeUnits) {
						Text("\($0.description)")
					}

					if let stakeClaimNFTs = viewStore.stakeClaimNFTs {
						ForEach(stakeClaimNFTs) {
							Text("\($0.id)")
								.background(Color.yellow)
								.foregroundColor(.red)
						}
					}
				}
			}
		}
	}
}

// MARK: - PoolUnitsList.LSUComponent.ViewState + CustomStringConvertible
extension PoolUnitsList.LSUComponent.ViewState: CustomStringConvertible {
	public var description: String {
		"\(id), \(imageURL), \(stakeClaimNFTs), \(title)"
	}
}

// MARK: - PoolUnitsList.LSUComponent.LiquidStakeUnitViewState + CustomStringConvertible
extension PoolUnitsList.LSUComponent.LiquidStakeUnitViewState: CustomStringConvertible {
	var description: String {
		"\(id), \(stakedAmmount), \(symbol), \(tokenAmount)"
	}
}
