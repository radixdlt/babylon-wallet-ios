import FeaturePrelude

extension AdvancedCreateSecurityStructureFlow.State {
	var viewState: AdvancedCreateSecurityStructureFlow.ViewState {
		.init()
	}
}

// MARK: - AdvancedCreateSecurityStructureFlow.View
extension AdvancedCreateSecurityStructureFlow {
	public struct ViewState: Equatable {
		// TODO: declare some properties
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<AdvancedCreateSecurityStructureFlow>

		public init(store: StoreOf<AdvancedCreateSecurityStructureFlow>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { _ in
				VStack {
					Text("Foo")
				}
			}
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - AdvancedCreateSecurityStructureFlow_Preview
struct AdvancedCreateSecurityStructureFlow_Preview: PreviewProvider {
	static var previews: some View {
		AdvancedCreateSecurityStructureFlow.View(
			store: .init(
				initialState: .previewValue,
				reducer: AdvancedCreateSecurityStructureFlow()
			)
		)
	}
}

extension AdvancedCreateSecurityStructureFlow.State {
	public static let previewValue = Self()
}
#endif
