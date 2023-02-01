import FeaturePrelude

// MARK: - DappInteraction.View
public extension DappInteraction {
	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<DappInteraction>

		public init(store: StoreOf<DappInteraction>) {
			self.store = store
		}
	}
}

public extension DappInteraction.View {
	var body: some View {
		WithViewStore(
			store,
			observe: ViewState.init(state:),
			send: { .view($0) }
		) { viewStore in
			// TODO: implement
//			NavigationStackStore

			Text("Implement: DappInteraction")
				.background(Color.yellow)
				.foregroundColor(.red)
				.onAppear { viewStore.send(.appeared) }
		}
	}
}

// MARK: - DappInteraction.View.ViewState
extension DappInteraction.View {
	struct ViewState: Equatable {
		init(state: DappInteraction.State) {
			// TODO: implement
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - DappInteraction_Preview
struct DappInteraction_Preview: PreviewProvider {
	static var previews: some View {
		DappInteraction.View(
			store: .init(
				initialState: .previewValue,
				reducer: DappInteraction()
			)
		)
	}
}
#endif
