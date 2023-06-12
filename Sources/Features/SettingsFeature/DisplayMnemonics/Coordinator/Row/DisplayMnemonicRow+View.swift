import FeaturePrelude

extension DisplayMnemonicRow.State {
	var connectedAccounts: String {
		let accountsCount = accountsForDeviceFactorSource.accounts.count
		if accountsCount == 1 {
			return L10n.SeedPhrases.SeedPhrase.oneConnectedAccount
		} else {
			return L10n.SeedPhrases.SeedPhrase.multipleConnectedAccounts(accountsCount)
		}
	}
}

// MARK: - DisplayMnemonicRow.View
extension DisplayMnemonicRow {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<DisplayMnemonicRow>

		public init(store: StoreOf<DisplayMnemonicRow>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: { $0 }, send: { .view($0) }) { viewStore in
				VStack(alignment: .leading) {
					Button {
						viewStore.send(.tapped)
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

// #if DEBUG
// import SwiftUI // NB: necessary for previews to appear
//
//// MARK: - DisplayMnemonicRow_Preview
// struct DisplayMnemonicRow_Preview: PreviewProvider {
//	static var previews: some View {
//		DisplayMnemonicRow.View(
//			store: .init(
//				initialState: .previewValue,
//				reducer: DisplayMnemonicRow()
//			)
//		)
//	}
// }
//
// extension DisplayMnemonicRow.State {
//    public static let previewValue = Self(deviceFactorSource: )
// }
// #endif
