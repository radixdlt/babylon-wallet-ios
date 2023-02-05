import FeaturePrelude

// MARK: - DappInteractionFlow.View
extension DappInteractionFlow {
	@MainActor
	struct View: SwiftUI.View {
		let store: StoreOf<DappInteractionFlow>
	}
}

extension DappInteractionFlow.View {
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

// MARK: - DappInteractionFlow.View.ViewState
extension DappInteractionFlow.View {
	struct ViewState: Equatable {
		init(state: DappInteractionFlow.State) {
			// TODO: implement
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - DappInteraction_Preview
struct DappInteraction_Preview: PreviewProvider {
	static var previews: some View {
		DappInteractionFlow.View(
			store: .init(
				initialState: .init(
					dappMetadata: .previewValue,
					interaction: .previewValueOneTimeAccount
				)!,
				reducer: DappInteractionFlow()
			)
		)
	}
}
#endif
