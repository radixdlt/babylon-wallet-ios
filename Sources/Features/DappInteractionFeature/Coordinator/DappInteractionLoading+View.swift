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
			store.stateless,
			observe: { false }, // TODO: use $0 when Apple makes Void conform to Equatable
			send: { .view($0) }
		) { viewStore in
			NavigationStack {
				ForceFullScreen {}
					.overlayLoadingView()
					.onAppear { viewStore.send(.appeared) }
					.alert(
						store.scope(
							state: \.errorAlert,
							action: { .view(.errorAlert($0)) }
						),
						dismiss: .systemDismissed
					)
				#if os(iOS)
					.toolbar {
						ToolbarItemGroup(placement: .navigationBarLeading) {
							CloseButton { viewStore.send(.dismissButtonTapped) }
						}
					}
				#endif
			}
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
