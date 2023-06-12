import FeaturePrelude

extension SecurityStructureConfigs.State {
	var viewState: SecurityStructureConfigs.ViewState {
		.init()
	}
}

// MARK: - SecurityStructureConfigs.View
extension SecurityStructureConfigs {
	public struct ViewState: Equatable {
		// TODO: declare some properties
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<SecurityStructureConfigs>

		public init(store: StoreOf<SecurityStructureConfigs>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				// TODO: implement
				Text("Implement: SecurityStructureConfigs")
					.background(Color.yellow)
					.foregroundColor(.red)
					.onFirstTask { @MainActor
						await viewStore.send(.onFirstTask).finish()
					}
			}
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - SecurityStructureConfigs_Preview
struct SecurityStructureConfigs_Preview: PreviewProvider {
	static var previews: some View {
		SecurityStructureConfigs.View(
			store: .init(
				initialState: .previewValue,
				reducer: SecurityStructureConfigs()
			)
		)
	}
}

extension SecurityStructureConfigs.State {
	public static let previewValue = Self()
}
#endif
