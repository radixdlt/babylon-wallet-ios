import FeaturePrelude

extension CreateSecurityStructureStart.State {
	var viewState: CreateSecurityStructureStart.ViewState {
		.init()
	}
}

// MARK: - CreateSecurityStructureStart.View
extension CreateSecurityStructureStart {
	public struct ViewState: Equatable {
		// TODO: declare some properties
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<CreateSecurityStructureStart>

		public init(store: StoreOf<CreateSecurityStructureStart>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				VStack {
					Text("Imple me")
				}
				.onAppear { viewStore.send(.appeared) }
			}
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - CreateSecurityStructureStart_Preview
struct CreateSecurityStructureStart_Preview: PreviewProvider {
	static var previews: some View {
		CreateSecurityStructureStart.View(
			store: .init(
				initialState: .previewValue,
				reducer: CreateSecurityStructureStart()
			)
		)
	}
}

extension CreateSecurityStructureStart.State {
	public static let previewValue = Self()
}
#endif
