import FeaturePrelude

extension DeviceFactorSource {
	var labelSeedPhraseKind: String {
		supportsOlympia ? L10n.DisplayMnemonics.labelSeedPhraseKindOlympia : L10n.DisplayMnemonics.labelSeedPhraseKind
	}

	var labelDate: String {
		supportsOlympia ? L10n.DisplayMnemonics.labelDateOlympia : L10n.DisplayMnemonics.labelDate
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
								Text("Reveal Seed Phrase")
									.textStyle(.body1Header)
									.foregroundColor(.app.gray1)
								Text("Connected to \(viewStore.accountsForDeviceFactorSource.accounts.count) accounts")
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

// MARK: - AccountsForDeviceFactorSourceView
struct AccountsForDeviceFactorSourceView: SwiftUI.View {
	let accountsForDeviceFactorSource: AccountsForDeviceFactorSource
	var deviceFactorSource: DeviceFactorSource {
		accountsForDeviceFactorSource.deviceFactorSource
	}

	var body: some View {
		VStack(alignment: .leading) {
			HStack {
				Image(asset: AssetResource.signingKey)
					.resizable()
					.frame(.smallest)

				VStack(alignment: .leading) {
					Text("Reveal Seed Phrase")
						.textStyle(.body1Header)
						.foregroundColor(.app.gray1)
					Text("Connected to \(accountsForDeviceFactorSource.accounts.count) accounts")
						.textStyle(.body2Regular)
						.foregroundColor(.app.gray2)
				}

				Spacer()
				Image(asset: AssetResource.chevronRight)
			}
			.border(.red)

			VStack(alignment: .leading, spacing: .small3) {
				ForEach(accountsForDeviceFactorSource.accounts) { account in
					SmallAccountCard(account: account)
						.cornerRadius(.small1)
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
