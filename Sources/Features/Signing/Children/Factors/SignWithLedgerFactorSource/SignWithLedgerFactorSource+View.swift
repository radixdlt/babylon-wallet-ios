import FeaturePrelude

extension SignWithLedgerFactorSource.State {
	var viewState: SignWithLedgerFactorSource.ViewState {
		.init()
	}
}

// MARK: - SignWithLedgerFactorSource.View
extension SignWithLedgerFactorSource {
	public struct ViewState: Equatable {
		// TODO: declare some properties
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<SignWithLedgerFactorSource>

		public init(store: StoreOf<SignWithLedgerFactorSource>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				VStack {
					Text("Sign transaction with Ledger")
				}
				.onAppear { viewStore.send(.appeared) }
			}
		}
	}
}
