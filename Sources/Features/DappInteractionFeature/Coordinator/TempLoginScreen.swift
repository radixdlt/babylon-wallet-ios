import FeaturePrelude

// MARK: - TempScreen
public struct TempScreen: ReducerProtocol {
	public typealias Store = StoreOf<Self>

	public struct State: Hashable {}

	public enum Action: Equatable {}

	public var body: some ReducerProtocolOf<Self> {
		Reduce { _, _ in .none }
	}
}

extension TempScreen {
	public struct View: SwiftUI.View {
		let store: Store

		public init(store: Store) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: ViewState.init(state:)) { _ in
				ZStack {
					Text("temp screen")
						.background(Color.red)
				}
				.navigationTitle("Temp screen")
			}
		}
	}

	struct ViewState: Equatable {
		init(state: State) {}
	}
}
