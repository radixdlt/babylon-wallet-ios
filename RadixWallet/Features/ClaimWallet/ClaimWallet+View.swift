import ComposableArchitecture
import SwiftUI

// MARK: - ClaimWallet.View
extension ClaimWallet {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<ClaimWallet>

		public init(store: StoreOf<ClaimWallet>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: { $0 }) { viewStore in
				VStack(spacing: 0) {
					Spacer()

					Image(.walletAppIcon)
						.padding(.bottom, .large1)

					Text(L10n.ConfigurationBackup.Automated.walletTransferredTitle)
						.foregroundColor(.app.gray1)
						.textStyle(.sheetTitle)
						.multilineTextAlignment(.center)
						.padding(.bottom, .medium1)

					Text(L10n.ConfigurationBackup.Automated.walletTransferredSubtitle)
						.foregroundColor(.app.gray2)
						.textStyle(.secondaryHeader)
						.multilineTextAlignment(.center)
						.padding(.bottom, .medium1)

					Text(L10n.ConfigurationBackup.Automated.walletTransferredExplanation1 + "\n\n" + L10n.ConfigurationBackup.Automated.walletTransferredExplanation2)
						.textStyle(.body1Regular)
						.multilineTextAlignment(.center)

					Spacer()

					VStack {
						Button(L10n.ConfigurationBackup.Automated.walletTransferredClearButton) {
							store.send(.view(.clearWalletButtonTapped))
						}
						.buttonStyle(.primaryRectangular)
						.padding(.bottom, .small2)

						Button(L10n.ConfigurationBackup.Automated.walletTransferredTransferBackButton) {
							store.send(.view(.transferBackButtonTapped))
						}
						.buttonStyle(.primaryText())
					}
				}
				.padding(.horizontal, .large1)
				.padding(.vertical, .medium3)
				.controlState(viewStore.screenState)
			}
		}
	}
}
