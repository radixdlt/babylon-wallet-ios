import ComposableArchitecture
import SwiftUI

extension ChooseReceivingAccountOnDelete.State {
	var hasAccountsWithEnoughXRD: Bool? {
		chooseAccounts.availableAccounts.wrappedValue?.contains(where: { accountType in
			guard case let .receiving(account) = accountType else { return false }
			return account.hasEnoughXRD
		})
	}
}

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

						Text("Before deleting this Account, choose another one to transfer your assets to.")
							.foregroundColor(.app.gray1)
							.textStyle(.body1Header)

						Text("The new Account must hold enough XRD to pay the transaction fee.")
							.foregroundColor(.app.gray1)
							.textStyle(.body1Regular)

						if viewStore.hasAccountsWithEnoughXRD == false {
							WarningErrorView(
								text: "You don’t have any other accounts with enough XRD.",
								type: .warning,
								useNarrowSpacing: true,
								useSmallerFontSize: true
							)
							.flushedLeft
						}

						ChooseAccounts.View(store: store.chooseAccounts)
					}
					.padding(.horizontal, .medium1)
					.padding(.bottom, .medium2)
					.multilineTextAlignment(.center)
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
			.destinations(with: store)
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

@MainActor
private extension View {
	func destinations(with store: StoreOf<ChooseReceivingAccountOnDelete>) -> some View {
		let destinationStore = store.destination
		return confirmDeletionAlert(with: destinationStore)
			.tooManyAssetsAlert(with: destinationStore)
	}

	private func confirmDeletionAlert(with destinationStore: PresentationStoreOf<ChooseReceivingAccountOnDelete.Destination>) -> some View {
		alert(store: destinationStore.scope(state: \.confirmSkipAlert, action: \.confirmSkipAlert))
	}

	private func tooManyAssetsAlert(with destinationStore: PresentationStoreOf<ChooseReceivingAccountOnDelete.Destination>) -> some View {
		alert(store: destinationStore.scope(state: \.tooManyAssetsAlert, action: \.tooManyAssetsAlert))
	}
}
