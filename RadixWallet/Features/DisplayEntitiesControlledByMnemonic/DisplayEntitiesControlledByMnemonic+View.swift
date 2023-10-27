import ComposableArchitecture
import SwiftUI
extension DisplayEntitiesControlledByMnemonic.State {
	var connectedAccounts: String {
		let accountsCount = accountsForDeviceFactorSource.accounts.count
		if accountsCount == 1 {
			return L10n.SeedPhrases.SeedPhrase.oneConnectedAccount
		} else {
			return L10n.SeedPhrases.SeedPhrase.multipleConnectedAccounts(accountsCount)
		}
	}

	var canNavigate: Bool {
		displayRevealMnemonicLink || mnemonicNeedsImport
	}
}

// MARK: - DisplayEntitiesControlledByMnemonic.View
extension DisplayEntitiesControlledByMnemonic {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<DisplayEntitiesControlledByMnemonic>

		public init(store: StoreOf<DisplayEntitiesControlledByMnemonic>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: { $0 }, send: { .view($0) }) { viewStore in
				VStack(alignment: .leading) {
					if viewStore.canNavigate {
						Button {
							viewStore.send(.navigateButtonTapped)
						} label: {
							HStack {
								if viewStore.displayRevealMnemonicLink {
									Image(asset: AssetResource.signingKey)
										.resizable()
										.frame(.smallest)

									VStack(alignment: .leading) {
										Text(L10n.SeedPhrases.SeedPhrase.reveal)
											.textStyle(.body1Header)
											.foregroundColor(.app.gray1)
										Text(viewStore.connectedAccounts)
											.textStyle(.body2Regular)
											.foregroundColor(.app.gray2)
									}
								} else if viewStore.mnemonicNeedsImport {
									WarningErrorView(
										text: "Recover Seed Phrase", // FIXME: strings
										type: .error,
										spacing: .small2
									)
								}

								Spacer()
								Image(asset: AssetResource.chevronRight)
							}
						}
					}
					VStack(alignment: .leading, spacing: .small3) {
						ForEach(viewStore.accountsForDeviceFactorSource.accounts) { account in
							SmallAccountCard(account: account)
								.cornerRadius(.small1)
						}
					}
				}
			}
		}
	}
}
