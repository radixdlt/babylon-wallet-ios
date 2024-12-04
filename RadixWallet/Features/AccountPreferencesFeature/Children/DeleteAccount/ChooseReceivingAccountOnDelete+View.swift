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
						Text(L10n.AccountSettings.MoveAssets.title)
							.lineSpacing(0)
							.textStyle(.sheetTitle)

						Text(L10n.AccountSettings.MoveAssets.message)
							.textStyle(.body1Header)

						Text(L10n.AccountSettings.MoveAssets.note)
							.textStyle(.body1Regular)

						if !viewStore.hasAccountsWithEnoughXRD {
							StatusMessageView(
								text: L10n.AccountSettings.MoveAssets.noAccountsWarning,
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
					.foregroundStyle(.app.gray1)
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

						Button(L10n.AccountSettings.MoveAssets.skipButton) {
							viewStore.send(.view(.skipButtonTapped))
						}
						.buttonStyle(.primaryText())
					}
					.controlState(viewStore.footerControlState)
				}
			}
			.destinations(with: store)
		}
	}
}

private extension StoreOf<ChooseReceivingAccountOnDelete> {
	var destination: PresentationStoreOf<ChooseReceivingAccountOnDelete.Destination> {
		scope(state: \.$destination, action: \.destination)
	}

	var chooseAccounts: StoreOf<ChooseAccounts> {
		scope(state: \.chooseAccounts, action: \.child.chooseAccounts)
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<ChooseReceivingAccountOnDelete>) -> some View {
		let destinationStore = store.destination
		return confirmSkipAlert(with: destinationStore)
			.tooManyAssetsAlert(with: destinationStore)
	}

	private func confirmSkipAlert(with destinationStore: PresentationStoreOf<ChooseReceivingAccountOnDelete.Destination>) -> some View {
		alert(store: destinationStore.scope(state: \.confirmSkipAlert, action: \.confirmSkipAlert))
	}

	private func tooManyAssetsAlert(with destinationStore: PresentationStoreOf<ChooseReceivingAccountOnDelete.Destination>) -> some View {
		alert(store: destinationStore.scope(state: \.tooManyAssetsAlert, action: \.tooManyAssetsAlert))
	}
}
