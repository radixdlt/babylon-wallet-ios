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
				// TODO: implement
				Text("Implement: SignWithLedgerFactorSource")
					.background(Color.yellow)
					.foregroundColor(.red)
					.onAppear { viewStore.send(.appeared) }
			}
		}
	}
}

// #if DEBUG
// import SwiftUI // NB: necessary for previews to appear
//
//// MARK: - SignWithLedgerFactorSource_Preview
// struct SignWithLedgerFactorSource_Preview: PreviewProvider {
//	static var previews: some View {
//		SignWithLedgerFactorSource.View(
//			store: .init(
//				initialState: .previewValue,
//				reducer: SignWithLedgerFactorSource()
//			)
//		)
//	}
// }
//
// extension SignWithLedgerFactorSource.State {
//	public static let previewValue = Self()
// }
// #endif
