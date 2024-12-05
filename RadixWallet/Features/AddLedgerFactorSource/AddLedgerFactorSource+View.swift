import ComposableArchitecture
import SwiftUI

extension AddLedgerFactorSource.State {
	var continueButtonControlState: ControlState {
		isWaitingForResponseFromLedger ? .loading(.local) : .enabled
	}
}

// MARK: - AddLedgerFactorSource.View
extension AddLedgerFactorSource {
	struct View: SwiftUI.View {
		let store: StoreOf<AddLedgerFactorSource>

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				NavigationStack {
					VStack(spacing: .zero) {
						ViewThatFits(in: .vertical) {
							InnerView(small: false)
							InnerView(small: true)
						}

						Spacer(minLength: .small1)

						Button(L10n.AddLedgerDevice.AddDevice.continue) {
							store.send(.view(.sendAddLedgerRequestButtonTapped))
						}
						.buttonStyle(.primaryRectangular)
						.controlState(store.continueButtonControlState)
						.padding(.horizontal, .medium3)
						.padding(.bottom, .large2)
					}
					.toolbar {
						ToolbarItem(placement: .cancellationAction) {
							CloseButton {
								store.send(.view(.closeButtonTapped))
							}
						}
					}
					.destination(store: store)
				}
			}
		}
	}

	struct InnerView: SwiftUI.View {
		let small: Bool

		var body: some SwiftUI.View {
			VStack(spacing: .zero) {
				Image(asset: AssetResource.iconHardwareLedger)
					.resizable()
					.frame(small ? .veryLarge : .huge)
					.padding(.top, small ? .large3 : .huge2)
					.padding(.bottom, small ? .large2 : .huge1)

				Text(L10n.AddLedgerDevice.AddDevice.title)
					.textStyle(.sheetTitle)
					.padding(.bottom, small ? .medium3 : .large3)

				Text(L10n.AddLedgerDevice.AddDevice.body1)
					.textStyle(.body1Regular)
					.padding(.horizontal, .large3)
					.padding(.bottom, .medium2)

				Text(L10n.AddLedgerDevice.AddDevice.body2)
					.textStyle(.body1Regular)
					.padding(.horizontal, .large3)
			}
			.multilineTextAlignment(.center)
			.foregroundColor(.app.gray1)
		}
	}
}

private extension StoreOf<AddLedgerFactorSource> {
	var destination: PresentationStoreOf<AddLedgerFactorSource.Destination> {
		func scopeState(state: State) -> PresentationState<AddLedgerFactorSource.Destination.State> {
			state.$destination
		}
		return scope(state: scopeState, action: Action.destination)
	}
}

@MainActor
private extension View {
	func destination(store: StoreOf<AddLedgerFactorSource>) -> some View {
		let destinationStore = store.destination
		return ledgerAlreadyExistsAlert(with: destinationStore)
			.nameLedger(with: destinationStore)
	}

	private func ledgerAlreadyExistsAlert(with destinationStore: PresentationStoreOf<AddLedgerFactorSource.Destination>) -> some View {
		alert(store: destinationStore.scope(state: \.ledgerAlreadyExistsAlert, action: \.ledgerAlreadyExistsAlert))
	}

	private func nameLedger(with destinationStore: PresentationStoreOf<AddLedgerFactorSource.Destination>) -> some View {
		navigationDestination(store: destinationStore.scope(state: \.nameLedger, action: \.nameLedger)) {
			NameLedgerFactorSource.View(store: $0)
		}
	}
}
