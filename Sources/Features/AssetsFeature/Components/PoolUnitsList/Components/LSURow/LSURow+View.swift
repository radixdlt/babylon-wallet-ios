import FeaturePrelude

extension PoolUnitsList.LSUComponent.State {
	var viewState: PoolUnitsList.LSUComponent.ViewState {
		.init(units: .init(), stakeClaimNFTs: .init())
	}
}

extension PoolUnitsList.ViewState {
	public static var preview: Self {
		.init(
			lsuComponents: .init(
				[
					.init(
						units: .init(
							uncheckedUniqueElements: [
								.init(
									thumbnail: .xrd,
									symbol: "XRD",
									tokenAmount: "2.0129822",
									stakedAmmount: "$138,021.03"
								),
							]
						),
						stakeClaimNFTs: .init(
							uncheckedUniqueElements: [
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
	struct UnitViewState: Identifiable, Equatable {
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

		let title: String = ""
		let imageURL: URL = .init(string: "www.wp.pl")!

		let units: IdentifiedArrayOf<UnitViewState>
		let stakeClaimNFTs: IdentifiedArrayOf<StakeClaimNFTViewState>
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: Store<PoolUnitsList.LSUComponent.ViewState, PoolUnitsList.LSUComponent.ViewAction>

		public init(store: Store<PoolUnitsList.LSUComponent.ViewState, PoolUnitsList.LSUComponent.ViewAction>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: identity, send: identity) { viewStore in
				Text("\(viewStore.state.description)")
					.background(Color.yellow)
					.foregroundColor(.red)
			}
		}
	}
}

// MARK: - PoolUnitsList.LSUComponent.ViewState + CustomStringConvertible
extension PoolUnitsList.LSUComponent.ViewState: CustomStringConvertible {
	public var description: String {
		"\(id), \(imageURL), \(stakeClaimNFTs), \(title), \(units)"
	}
}
