extension FactorSourceAccess.State {
	var viewState: FactorSourceAccess.ViewState {
		.init(
			title: "Signature Request",
			message: "Authenticate to your phone to sign.",
			device: device,
			retryEnabled: retryEnabled
		)
	}

	private var device: String? {
		nil
	}

	private var retryEnabled: Bool {
		false
	}
}

// MARK: - FactorSourceAccess.View

public extension FactorSourceAccess {
	struct ViewState: Equatable {
		let title: String
		let message: String
		let device: String?
		let retryEnabled: Bool
	}

	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<FactorSourceAccess>

		public init(store: StoreOf<FactorSourceAccess>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				VStack(spacing: .medium3) {
					Image(asset: AssetResource.signingKey)
						.foregroundColor(.app.gray3)

					Text(viewStore.title)
						.textStyle(.sheetTitle)
						.foregroundColor(.app.gray1)

					Text(viewStore.message)
						.textStyle(.body1Regular)
						.foregroundColor(.app.gray1)

					device(viewStore.device)

					if viewStore.retryEnabled {
						Button {
							viewStore.send(.retryButtonTapped)
						} label: {
							Text("Retry")
								.textStyle(.body1Header)
								.foregroundColor(.app.blue2)
								.frame(height: .standardButtonHeight)
								.frame(maxWidth: .infinity)
						}
					}
				}
				.padding(.horizontal, .large2)
			}
			.withNavigationBar {
				store.send(.view(.closeButtonTapped))
			}
			.presentationDetents([.fraction(0.66)])
			.presentationDragIndicator(.visible)
			.onFirstTask { @MainActor in
				await store.send(.view(.onFirstTask)).finish()
			}
		}

		@ViewBuilder
		private func device(_ value: String?) -> some SwiftUI.View {
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
