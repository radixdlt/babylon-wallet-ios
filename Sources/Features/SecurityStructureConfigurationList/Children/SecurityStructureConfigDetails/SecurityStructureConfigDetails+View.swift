import FeaturePrelude

extension SecurityStructureConfigDetails.State {
	var viewState: SecurityStructureConfigDetails.ViewState {
		.init(label: config.label.rawValue)
	}
}

// MARK: - SecurityStructureConfigDetails.View
extension SecurityStructureConfigDetails {
	public struct ViewState: Equatable {
		let label: String
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<SecurityStructureConfigDetails>

		public init(store: StoreOf<SecurityStructureConfigDetails>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				VStack {
					Text("\(viewStore.label)")
						.font(.app.sheetTitle)
						.background(Color.yellow)
						.foregroundColor(.red)
				}
				.onAppear { viewStore.send(.appeared) }
			}
		}
	}
}

// #if DEBUG
// import SwiftUI // NB: necessary for previews to appear
//
//// MARK: - SecurityStructureConfigDetails_Preview
// struct SecurityStructureConfigDetails_Preview: PreviewProvider {
//	static var previews: some View {
//		SecurityStructureConfigDetails.View(
//			store: .init(
//				initialState: .previewValue,
//				reducer: SecurityStructureConfigDetails()
//			)
//		)
//	}
// }
//
// extension SecurityStructureConfigDetails.State {
//	public static let previewValue = Self()
// }
// #endif
