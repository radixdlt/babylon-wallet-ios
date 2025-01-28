import SwiftUI

// MARK: - FactorSourceAccess.View
extension FactorSourceAccess {
	struct View: SwiftUI.View {
		let store: StoreOf<FactorSourceAccess>

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
			VStack(spacing: .zero) {
				VStack(spacing: .medium3) {
					Image(.signingKey)
						.foregroundColor(.app.gray3)

					VStack(spacing: .small2) {
						Text(store.title)
							.textStyle(.sheetTitle)

						Text(LocalizedStringKey(store.message))
							.textStyle(.body1Regular)
					}
					.foregroundColor(.app.gray1)

					card
					retry
					skip
				}
				.multilineTextAlignment(.center)
				.padding(.horizontal, .large2)

				Spacer()
			}
		}

		@ViewBuilder
		private var card: some SwiftUI.View {
			if store.showCard {
				if let factorSource = store.factorSource {
					FactorSourceCard(
						kind: .instance(
							factorSource: factorSource,
							kind: .short(showDetails: false)
						),
						mode: .display
					)
				} else {
					ProgressView()
				}
			}
		}

		@ViewBuilder
		private var retry: some SwiftUI.View {
			if store.isRetryEnabled {
				Button(L10n.Common.retry) {
					store.send(.view(.retryButtonTapped))
				}
				.buttonStyle(.primaryText(height: .standardButtonHeight))
			}
		}

		@ViewBuilder
		private var skip: some SwiftUI.View {
			if store.isSkipEnabled {
				Button(L10n.FactorSourceActions.useDifferentFactor) {
					store.send(.view(.skipButtonTapped))
				}
				.buttonStyle(.primaryText(height: .standardButtonHeight))
			}
		}
	}
}

private extension StoreOf<FactorSourceAccess> {
	var destination: PresentationStoreOf<FactorSourceAccess.Destination> {
		func scopeState(state: State) -> PresentationState<FactorSourceAccess.Destination.State> {
			state.$destination
		}
		return scope(state: scopeState, action: Action.destination)
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<FactorSourceAccess>) -> some View {
		let destinationStore = store.destination
		return errorAlert(with: destinationStore)
	}

	private func errorAlert(with destinationStore: PresentationStoreOf<FactorSourceAccess.Destination>) -> some View {
		alert(store: destinationStore.scope(state: \.errorAlert, action: \.errorAlert))
	}
}
