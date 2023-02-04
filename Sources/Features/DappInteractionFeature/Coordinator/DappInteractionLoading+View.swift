import FeaturePrelude

// MARK: - DappInteractionLoading.View
extension DappInteractionLoading {
	struct ViewState: Equatable {
		let screenState: ControlState

		init(state: State) {
			self.screenState = state.isLoading
				? .loading(.global(text: L10n.DApp.MetadataLoading.prompt))
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
				.controlState(viewStore.screenState)
			}
		}
	}
}

#if DEBUG
import GatewayAPI
import SwiftUI // NB: necessary for previews to appear

// MARK: - DappInteraction_Preview
struct DappInteractionLoading_Preview: PreviewProvider {
	static var previews: some View {
		DappInteractionLoading.View(
			store: .init(
				initialState: .previewValue,
				reducer: DappInteractionLoading()
			) {
				$0.gatewayAPIClient.accountMetadataByAddress = { _ in
					try await Task.sleep(for: .seconds(3))
					return GatewayAPI.EntityMetadataResponse(
						ledgerState: .previewValue,
						address: "abc",
						metadata: .init(items: [])
					)
				}
			}
		)
		.presentsLoadingViewOverlay()
	}
}

extension DappInteractionLoading.State {
	static let previewValue: Self = .init(
		interaction: .previewValueOneTimeAccount
	)
}
#endif
