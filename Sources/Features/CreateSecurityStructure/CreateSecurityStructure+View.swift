import FeaturePrelude

extension CreateSecurityStructure.State {
	var viewState: CreateSecurityStructure.ViewState {
		.init()
	}
}

// MARK: - CreateSecurityStructure.View
extension CreateSecurityStructure {
	public struct ViewState: Equatable {}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<CreateSecurityStructure>

		public init(store: StoreOf<CreateSecurityStructure>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { _ in
				VStack {
					Text("Imple me")
				}
			}
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - CreateSecurityStructure_Preview
struct CreateSecurityStructure_Preview: PreviewProvider {
	static var previews: some View {
		CreateSecurityStructure.View(
			store: .init(
				initialState: .previewValue,
				reducer: CreateSecurityStructure()
			)
		)
	}
}

extension CreateSecurityStructure.State {
	public static let previewValue = Self()
}
#endif
