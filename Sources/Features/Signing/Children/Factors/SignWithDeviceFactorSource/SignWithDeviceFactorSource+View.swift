import FeaturePrelude

extension SignWithDeviceFactorSource.State {
	var viewState: SignWithDeviceFactorSource.ViewState {
		.init()
	}
}

// MARK: - SignWithDeviceFactorSource.View
extension SignWithDeviceFactorSource {
	public struct ViewState: Equatable {
		// TODO: declare some properties
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<SignWithDeviceFactorSource>

		public init(store: StoreOf<SignWithDeviceFactorSource>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				VStack {
					Text("Sign transaction with phone")
				}
				.onAppear { viewStore.send(.appeared) }
			}
		}
	}
}
