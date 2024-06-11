import ComposableArchitecture
import SwiftUI

// MARK: - DappInteractionLoading.View
extension DappInteractionLoading {
	struct ViewState: Equatable {
		let screenState: ControlState

		init(state: State) {
			self.screenState = state.isLoading
				? .loading(.global(text: L10n.DAppRequest.metadataLoadingPrompt))
				: .enabled
		}
	}

	@MainActor
	struct View: SwiftUI.View {
		let store: StoreOf<DappInteractionLoading>

		var body: some SwiftUI.View {
			WithViewStore(
				store,
				observe: DappInteractionLoading.ViewState.init,
				send: { .view($0) }
			) { viewStore in
				NavigationStack {
					ForceFullScreen {}
						.controlState(viewStore.screenState)
						.onAppear { viewStore.send(.appeared) }
						.alert(
							store: store.scope(
								state: \.$errorAlert,
								action: { .view(.errorAlert($0)) }
							)
						)
						.toolbar {
							ToolbarItemGroup(placement: .navigationBarLeading) {
								CloseButton { viewStore.send(.dismissButtonTapped) }
							}
						}
				}
			}
		}
	}
}

#if DEBUG
import ComposableArchitecture
import SwiftUI

// MARK: - DappInteraction_Preview
struct DappInteractionLoading_Preview: PreviewProvider {
	static var previews: some View {
		DappInteractionLoading.View(
			store: .init(initialState: .previewValue) {
				DappInteractionLoading()
					.dependency(\.gatewayAPIClient, .previewValueDappMetadataFailure)
					.dependency(\.gatewayAPIClient, .previewValueDappMetadataSuccess)
			}
		)
		.presentsLoadingViewOverlay()
	}
}

extension DappInteractionLoading.State {
	static let previewValue: Self = .init(
		interaction: .previewValueAllRequests() // .previewValueOneTimeAccount
	)
}
#endif
