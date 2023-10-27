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
					if viewStore.displayRevealMnemonicLink {
						Button {
							viewStore.send(.displayMnemonic)
						} label: {
							HStack {
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

								Spacer()
								Image(asset: AssetResource.chevronRight)
							}
						}
						if viewStore.promptUserToBackUpMnemonic {
							WarningErrorView(
								text: "Please write down your seed phrase",
								type: .error,
								useNarrowSpacing: true
							)
						}
					} else if viewStore.mnemonicNeedsImport {
						Button {
							viewStore.send(.importMnemonic)
						} label: {
							HStack {
								VStack {
									WarningErrorView(
										text: "Please recover your seed phrase", // FIXME: strings
										type: .error,
										useNarrowSpacing: true
									)
									Text(viewStore.connectedAccounts)
										.textStyle(.body2Regular)
										.foregroundColor(.app.gray2)
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
