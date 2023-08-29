import FeaturePrelude

// MARK: - Completion.View
extension DappInteractionSuccess {
	public struct ViewState: Equatable {
		public let title: String
		public let subtitle: String

		public init(state: DappInteractionSuccess.State) {
			title = L10n.DAppRequest.Completion.title
			subtitle = state.item.dappName
		}
	}

	@MainActor
	public struct View: SwiftUI.View {
		public let store: StoreOf<DappInteractionSuccess>

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: ViewState.init, send: { .view($0) }) { viewStore in
				WithNavigationBar {
					viewStore.send(.closeButtonTapped)
				} content: {
					VStack(spacing: .medium2) {
						Image(asset: AssetResource.successCheckmark)

						Text(viewStore.title)
							.foregroundColor(.app.gray1)
							.textStyle(.sheetTitle)

						Text(viewStore.subtitle)
							.foregroundColor(.app.gray1)
							.textStyle(.body1Regular)
							.multilineTextAlignment(.center)
					}
					.padding(.horizontal, .medium2)
					.padding(.bottom, .medium3)
				}
			}
			.presentationDragIndicator(.visible)
			.presentationDetents([.height(.smallDetent)])
		}
	}
}
