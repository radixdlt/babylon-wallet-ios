import FeaturePrelude

extension SecurityStructureConfigurationList.State {
	var viewState: SecurityStructureConfigurationList.ViewState {
		.init()
	}
}

// MARK: - SecurityStructureConfigurationList.View
extension SecurityStructureConfigurationList {
	public struct ViewState: Equatable {
		// TODO: declare some properties
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<SecurityStructureConfigurationList>

		public init(store: StoreOf<SecurityStructureConfigurationList>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				// TODO: implement
				Text("Implement: SecurityStructureConfigurationList")
					.background(Color.yellow)
					.foregroundColor(.red)
					.onAppear { viewStore.send(.appeared) }
			}
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - SecurityStructureConfigurationList_Preview
struct SecurityStructureConfigurationList_Preview: PreviewProvider {
	static var previews: some View {
		SecurityStructureConfigurationList.View(
			store: .init(
				initialState: .previewValue,
				reducer: SecurityStructureConfigurationList()
			)
		)
	}
}

extension SecurityStructureConfigurationList.State {
	public static let previewValue = Self()
}
#endif
