// MARK: - FactorSourceAccess.View

public extension FactorSourceAccess {
	struct ViewState: Equatable {
		let title: String
		let message: String
		let externalDevice: String?
		let isRetryEnabled: Bool
		let height: CGFloat
	}

	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<FactorSourceAccess>

		public init(store: StoreOf<FactorSourceAccess>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				content(viewStore)
					.withNavigationBar {
						viewStore.send(.closeButtonTapped)
					}
					.presentationDetents([.fraction(viewStore.height), .large])
					.presentationDragIndicator(.visible)
					.interactiveDismissDisabled()
					.presentationBackground(.blur)
					.onFirstTask { @MainActor in
						await store.send(.view(.onFirstTask)).finish()
					}
			}
		}

		@ViewBuilder
		private func content(_ viewStore: ViewStoreOf<FactorSourceAccess>) -> some SwiftUI.View {
			VStack(spacing: .medium3) {
				Image(asset: AssetResource.signingKey)
					.foregroundColor(.app.gray3)

				Text(viewStore.title)
					.textStyle(.sheetTitle)
					.foregroundColor(.app.gray1)

				Text(LocalizedStringKey(viewStore.message))
					.textStyle(.body1Regular)
					.foregroundColor(.app.gray1)

				externalDevice(viewStore.externalDevice)

				if viewStore.isRetryEnabled {
					Button {
						viewStore.send(.retryButtonTapped)
					} label: {
						Text(L10n.Common.retry)
							.textStyle(.body1Header)
							.foregroundColor(.app.blue2)
							.frame(height: .standardButtonHeight)
							.frame(maxWidth: .infinity)
					}
				}
			}
			.multilineTextAlignment(.center)
			.padding(.horizontal, .large2)
		}

		@ViewBuilder
		private func externalDevice(_ value: String?) -> some SwiftUI.View {
			if let value {
				HStack(spacing: .medium3) {
					Image(asset: AssetResource.signingKey)
						.resizable()
						.frame(.smallest)
						.foregroundColor(.app.gray3)

					Text(value)
						.textStyle(.secondaryHeader)
						.foregroundColor(.app.gray1)
						.padding(.trailing, .small2)
				}
				.padding(.medium2)
				.background(Color.app.gray5)
				.cornerRadius(.large1)
			}
		}
	}
}
