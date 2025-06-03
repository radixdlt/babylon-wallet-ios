import ComposableArchitecture
import SwiftUI

// MARK: - ClaimWallet.View
extension ClaimWallet {
	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<ClaimWallet>

		init(store: StoreOf<ClaimWallet>) {
			self.store = store
		}

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				VStack(spacing: 0) {
					Spacer()

					Image(.walletAppIcon)
						.padding(.bottom, .large1)

					Text(L10n.ConfigurationBackup.Automated.walletTransferredTitle)
						.foregroundColor(.primaryText)
						.textStyle(.sheetTitle)
						.multilineTextAlignment(.center)
						.padding(.bottom, .medium1)

					Text(L10n.ConfigurationBackup.Automated.walletTransferredSubtitle)
						.foregroundColor(.secondaryText)
						.textStyle(.secondaryHeader)
						.multilineTextAlignment(.center)
						.padding(.bottom, .small1)

					Text(L10n.ConfigurationBackup.Automated.walletTransferredExplanation1 + "\n\n" + L10n.ConfigurationBackup.Automated.walletTransferredExplanation2)
						.textStyle(.body1Regular)
						.multilineTextAlignment(.center)
						.padding(.bottom, .small1)

					Spacer()

					VStack(spacing: .medium1) {
						Button(L10n.FactoryReset.resetWallet) {
							store.send(.view(.clearWalletButtonTapped))
						}
						.buttonStyle(.primaryRectangular(isDestructive: true))

						Button(L10n.ConfigurationBackup.Automated.walletTransferredTransferBackButton) {
							store.send(.view(.transferBackButtonTapped))
						}
						.buttonStyle(.primaryText())
					}
				}
				.padding(.horizontal, .medium3)
				.padding(.vertical, .medium3)
				.controlState(store.screenState)
			}
			.destinations(with: store)
		}
	}
}

private extension StoreOf<ClaimWallet> {
	var destination: PresentationStoreOf<ClaimWallet.Destination> {
		func scopeState(state: State) -> PresentationState<ClaimWallet.Destination.State> {
			state.$destination
		}
		return scope(state: scopeState, action: Action.destination)
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<ClaimWallet>) -> some View {
		let destination = store.destination
		return confirmReset(with: destination)
	}

	private func confirmReset(with destinationStore: PresentationStoreOf<ClaimWallet.Destination>) -> some View {
		alert(store: destinationStore.scope(state: \.confirmReset, action: \.confirmReset))
	}
}
