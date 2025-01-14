import SwiftUI

// MARK: - NewFactorSourceAccess.View
extension NewFactorSourceAccess {
	struct View: SwiftUI.View {
		let store: StoreOf<NewFactorSourceAccess>

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				content
					.withNavigationBar {
						store.send(.view(.closeButtonTapped))
					}
					.presentationDetents([.fraction(store.height), .large])
					.presentationDragIndicator(.visible)
					.interactiveDismissDisabled()
					.presentationBackground(.blur)
					.onFirstTask { @MainActor in
						await store.send(.view(.onFirstTask)).finish()
					}
					.destinations(with: store)
			}
		}

		private var content: some SwiftUI.View {
			VStack(spacing: .medium3) {
				Image(.signingKey)
					.foregroundColor(.app.gray3)

				Text(store.title)
					.textStyle(.sheetTitle)
					.foregroundColor(.app.gray1)

				Text(LocalizedStringKey(store.message))
					.textStyle(.body1Regular)
					.foregroundColor(.app.gray1)

				description

				if store.isRetryEnabled {
					Button {
						store.send(.view(.retryButtonTapped))
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
		private var description: some SwiftUI.View {
			if let label = store.label {
				HStack(spacing: .medium2) {
					Image(store.kind.icon)
						.resizable()
						.frame(.smallest)
						.foregroundColor(.app.gray3)

					Text(label)
						.textStyle(.secondaryHeader)
						.foregroundColor(.app.gray1)
						.padding(.trailing, .small2)

					Spacer()
				}
				.padding(.medium2)
				.background(Color.app.gray5)
				.cornerRadius(.small1)
			} else {
				ProgressView()
			}
		}
	}
}

private extension StoreOf<NewFactorSourceAccess> {
	var destination: PresentationStoreOf<NewFactorSourceAccess.Destination> {
		func scopeState(state: State) -> PresentationState<NewFactorSourceAccess.Destination.State> {
			state.$destination
		}
		return scope(state: scopeState, action: Action.destination)
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<NewFactorSourceAccess>) -> some View {
		let destinationStore = store.destination
		return errorAlert(with: destinationStore)
	}

	private func errorAlert(with destinationStore: PresentationStoreOf<NewFactorSourceAccess.Destination>) -> some View {
		alert(store: destinationStore.scope(state: \.errorAlert, action: \.errorAlert))
	}
}
