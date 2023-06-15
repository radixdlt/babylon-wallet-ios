import FeaturePrelude

extension ManageSomeFactorSource.State {
	var viewState: ManageSomeFactorSource.ViewState {
		.init()
	}
}

// MARK: - ManageSomeFactorSource.View
extension ManageSomeFactorSource {
	public struct ViewState: Equatable {
		// TODO: declare some properties
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<ManageSomeFactorSource>

		public init(store: StoreOf<ManageSomeFactorSource>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				// TODO: implement
				Text("Implement: ManageSomeFactorSource")
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
//// MARK: - ManageSomeFactorSource_Preview
// struct ManageSomeFactorSource_Preview: PreviewProvider {
//	static var previews: some View {
//		ManageSomeFactorSource.View(
//			store: .init(
//				initialState: .previewValue,
//				reducer: ManageSomeFactorSource()
//			)
//		)
//	}
// }
//
// extension ManageSomeFactorSource.State {
//	public static let previewValue = Self()
// }
// #endif
