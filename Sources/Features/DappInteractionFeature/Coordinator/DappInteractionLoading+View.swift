import FeaturePrelude

// MARK: - DappInteractionLoading.View
extension DappInteractionLoading {
	@MainActor
	struct View: SwiftUI.View {
		let store: StoreOf<DappInteractionLoading>
	}
}

extension DappInteractionLoading.View {
	var body: some View {
		WithViewStore(
			store,
			observe: ViewState.init(state:),
			send: { .view($0) }
		) { viewStore in
			Text("Implement: DappInteraction")
				.background(Color.yellow)
				.foregroundColor(.red)
				.onAppear { viewStore.send(.appeared) }
		}
	}
}

// MARK: - DappInteractionLoading.View.ViewState
extension DappInteractionLoading.View {
	struct ViewState: Equatable {
		init(state: DappInteractionLoading.State) {
			// TODO: implement
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - DappInteraction_Preview
struct DappInteractionLoading_Preview: PreviewProvider {
	static var previews: some View {
		DappInteractionLoading.View(
			store: .init(
				initialState: .previewValue,
				reducer: DappInteractionLoading()
			)
		)
	}
}

extension DappInteractionLoading.State {
	static let previewValue: Self = .init(
		interaction: .previewValueOneTimeAccount
	)
}
#endif
