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
				Color.white
					.onAppear { viewStore.send(.appeared) }
			}
		}
	}
}

// #if DEBUG
// import SwiftUI // NB: necessary for previews to appear
//
//// MARK: - SignWithDeviceFactorSource_Preview
// struct SignWithDeviceFactorSource_Preview: PreviewProvider {
//	static var previews: some View {
//		SignWithDeviceFactorSource.View(
//			store: .init(
//				initialState: .previewValue,
//				reducer: SignWithDeviceFactorSource()
//			)
//		)
//	}
// }
//
// extension SignWithDeviceFactorSource.State {
//	public static let previewValue = Self()
// }
// #endif
