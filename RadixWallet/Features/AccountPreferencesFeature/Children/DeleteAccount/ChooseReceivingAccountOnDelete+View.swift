import ComposableArchitecture
import SwiftUI

// MARK: - ChooseReceivingAccountOnDelete.View
extension ChooseReceivingAccountOnDelete {
	@MainActor
	struct View: SwiftUI.View {
		let store: StoreOf<ChooseReceivingAccountOnDelete>

		var body: some SwiftUI.View {
			WithViewStore(store, observe: { $0 }) { viewStore in
				ScrollView {
					VStack(spacing: .medium2) {
						Text("Move Assets to Another Account")
							.foregroundColor(.app.gray1)
							.lineSpacing(0)
							.textStyle(.sheetTitle)
							.multilineTextAlignment(.center)

						Text("Before deleting this Account, choose another one to transfer your assets to. The new Account must hold enough XRD to pay the transaction fee.")
							.foregroundColor(.app.gray1)
							.textStyle(.body1Regular)
							.multilineTextAlignment(.leading)

						ChooseAccounts.View(store: store.chooseAccounts)
					}
					.padding(.horizontal, .medium1)
					.padding(.bottom, .medium2)
				}
				.footer {
					VStack(spacing: .medium3) {
						WithControlRequirements(
							viewStore.chooseAccounts.selectedAccounts,
							forAction: { viewStore.send(.view(.continueButtonTapped($0))) }
						) { action in
							Button(L10n.DAppRequest.ChooseAccounts.continue, action: action)
								.buttonStyle(.primaryRectangular)
						}

						Button("Skip") {
							viewStore.send(.view(.skipButtonTapped))
						}
						.buttonStyle(.primaryText())
					}
				}
			}
			//            .destinations(with: store)
		}
	}
}

private extension StoreOf<ChooseReceivingAccountOnDelete> {
	var destination: PresentationStoreOf<ChooseReceivingAccountOnDelete.Destination> {
		func scopeState(state: State) -> PresentationState<ChooseReceivingAccountOnDelete.Destination.State> {
			state.$destination
		}
		return scope(state: scopeState, action: Action.destination)
	}

	var chooseAccounts: StoreOf<ChooseAccounts> {
		scope(state: \.chooseAccounts) { .child(.chooseAccounts($0)) }
	}
}
