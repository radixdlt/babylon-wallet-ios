import EngineToolkit
import FeaturePrelude
import ImportLegacyWalletClient

// MARK: - AccountsToImport.View
extension AccountsToImport {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<AccountsToImport>

		public init(store: StoreOf<AccountsToImport>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: { $0 }, send: { .view($0) }) { viewStore in
				ScrollView {
					VStack(spacing: .small1) {
						Text(L10n.ImportOlympiaAccounts.AccountsToImport.subtitle)

						ForEach(viewStore.scannedAccounts) { account in
							AccountRow(viewState: account.viewState)
						}
					}
					.padding(.horizontal, .medium1)
					.padding(.bottom, .medium2)
				}
				.footer {
					Button(viewStore.buttonTitle) {
						viewStore.send(.continueButtonTapped)
					}
					.buttonStyle(.primaryRectangular)
				}
			}
			.navigationTitle(L10n.ImportOlympiaAccounts.AccountsToImport.title)
			.navigationBarTitleDisplayMode(.large)
		}
	}
}

extension OlympiaAccountToMigrate {
	public var viewState: AccountRow.ViewState {
		.init(
			accountName: displayName?.rawValue ?? L10n.ImportOlympiaAccounts.AccountsToImport.unnamed,
			olympiaAddress: address.address.rawValue,
			appearanceID: .fromIndex(Int(addressIndex)),
			derivationPath: path.derivationPath,
			olympiaAccountType: accountType
		)
	}
}

// MARK: - AccountRow
public struct AccountRow: View {
	public struct ViewState: Equatable {
		public let accountName: String
		public let olympiaAddress: String
		public let appearanceID: Profile.Network.Account.AppearanceID
		public let derivationPath: String
		public let olympiaAccountType: Olympia.AccountType
	}

	public let viewState: ViewState

	public init(viewState: ViewState) {
		self.viewState = viewState
	}

	public var body: some View {
		VStack(alignment: .leading, spacing: .medium2) {
			Text(viewState.accountName)
				.textStyle(.secondaryHeader)
				.foregroundColor(.white)
				.padding(.bottom, .small2)
			Text(viewState.olympiaAccountType.label)
				.textStyle(.body2Regular)
				.foregroundColor(.app.gray4)

			Text(L10n.ImportOlympiaAccounts.AccountsToImport.olympiaAddressLabel)
				.textStyle(.body2Link)
				.foregroundColor(.white)
				.padding(.bottom, .small2)
			Text(viewState.olympiaAddress.formatted(.default))
				.textStyle(.body2Regular)
				.foregroundColor(.app.gray4)

			Text(L10n.ImportOlympiaAccounts.AccountsToImport.newAddressLabel)
				.textStyle(.body2Link)
				.foregroundColor(.white)
				.padding(.bottom, .small2)
			Text(viewState.derivationPath.formatted(.default))
				.textStyle(.body2Regular)
				.foregroundColor(.app.gray4)
		}
		.padding(.medium1)
		.background(viewState.appearanceID.gradient)
		.cornerRadius(.small1)
	}
}

// MARK: - Extensions

extension AccountsToImport.State {
	var buttonTitle: String {
		let accountCount = scannedAccounts.count
		if accountCount == 1 {
			return L10n.ImportOlympiaAccounts.AccountsToImport.buttonOneAcccount
		} else {
			return L10n.ImportOlympiaAccounts.AccountsToImport.buttonManyAccounts(accountCount)
		}
	}
}

extension Olympia.AccountType {
	var label: String {
		switch self {
		case .software:
			return L10n.ImportOlympiaAccounts.AccountsToImport.legacyAccount
		case .hardware:
			return L10n.ImportOlympiaAccounts.AccountsToImport.ledgerAccount
		}
	}
}
