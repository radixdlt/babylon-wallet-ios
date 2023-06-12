import FeaturePrelude

extension EditSecurityStructureConfiguration.State {
	var viewState: EditSecurityStructureConfiguration.ViewState {
		.init()
	}
}

// MARK: - EditSecurityStructureConfiguration.View
extension EditSecurityStructureConfiguration {
	public struct ViewState: Equatable {
		// TODO: declare some properties
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<EditSecurityStructureConfiguration>

		public init(store: StoreOf<EditSecurityStructureConfiguration>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				// TODO: implement
				Text("Implement: EditSecurityStructureConfiguration")
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
//// MARK: - EditSecurityStructureConfiguration_Preview
// struct EditSecurityStructureConfiguration_Preview: PreviewProvider {
//	static var previews: some View {
//		EditSecurityStructureConfiguration.View(
//			store: .init(
//				initialState: .previewValue,
//				reducer: EditSecurityStructureConfiguration()
//			)
//		)
//	}
// }
//
// extension EditSecurityStructureConfiguration.State {
//	public static let previewValue = Self()
// }
// #endif
