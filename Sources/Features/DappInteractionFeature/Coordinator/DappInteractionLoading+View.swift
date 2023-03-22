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
						.controlState(viewStore.screenState)
						.onAppear { viewStore.send(.appeared) }
						.alert(
							store: store.scope(
								state: \.$errorAlert,
								action: { .view(.errorAlert($0)) }
							)
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
}

#if DEBUG
// import SwiftUI // NB: necessary for previews to appear
//
//// MARK: - DappInteraction_Preview
// struct DappInteractionLoading_Preview: PreviewProvider {
//	static var previews: some View {
//		DappInteractionLoading.View(
//			store: .init(
//				initialState: .previewValue,
//				reducer: DappInteractionLoading()
//					.dependency(\.gatewayAPIClient, .previewValueDappMetadataFailure)
//					.dependency(\.gatewayAPIClient, .previewValueDappMetadataSuccess)
//			)
//		)
//		.presentsLoadingViewOverlay()
//	}
// }
//
// extension DappInteractionLoading.State {
//	static let previewValue: Self = .init(
//		interaction: .previewValueOneTimeAccount
//	)
// }
//
// import GatewayAPI
// extension GatewayAPIClient {
//        // TODO: should be with(noop) — see GatewayAPIClient+Mock.swift for deets.
//        static let previewValueDappMetadataSuccess = with(previewValue) {
//                $0.getEntityMetadata = { @Sendable _ in
//                        try await Task.sleep(for: .seconds(2))
//                        return GatewayAPI.StateEntityMetadata(
//                                ledgerState: .previewValue,
//                                address: "abc",
//                                metadata: .init(items: [])
//                        )
//                }
//        }
//
//        // TODO: should be with(noop) — see GatewayAPIClient+Mock.swift for deets.
//        static let previewValueDappMetadataFailure = with(previewValue) {
//                $0.accountMetadataByAddress = { @Sendable _ in
//                        try await Task.sleep(for: .seconds(2))
//                        throw NoopError()
//                }
//        }
// }
#endif
