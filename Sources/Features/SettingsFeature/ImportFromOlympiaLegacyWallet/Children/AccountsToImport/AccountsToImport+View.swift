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
					VStack(spacing: .medium3) {
						Text(L10n.ImportOlympiaAccounts.AccountsToImport.title)
							.textStyle(.sheetTitle)
							.foregroundColor(.app.gray1)
							.multilineTextAlignment(.center)
							.padding(.horizontal, .large2)

						Text(L10n.ImportOlympiaAccounts.AccountsToImport.subtitle)
							.textStyle(.body1Regular)
							.foregroundColor(.app.gray1)
							.multilineTextAlignment(.center)
							.padding(.horizontal, .large2)

						ForEach(viewStore.scannedAccounts) { account in
							AccountView(viewState: account.viewState)
								.padding(.horizontal, .medium3)
						}
					}
					.padding(.bottom, .medium3)
				}
				.footer {
					Button(viewStore.buttonTitle) {
						viewStore.send(.continueButtonTapped)
					}
					.buttonStyle(.primaryRectangular)
				}
			}
		}
	}
}

extension OlympiaAccountToMigrate {
	public var viewState: AccountView.ViewState {
		.init(
			accountName: displayName?.rawValue ?? L10n.ImportOlympiaAccounts.AccountsToImport.unnamed,
			olympiaAddress: address.address.rawValue,
			appearanceID: .fromIndex(Int(addressIndex)),
			derivationPath: path.derivationPath,
			olympiaAccountType: accountType
		)
	}
}

// MARK: - AccountView
public struct AccountView: View {
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
		HStack(spacing: 0) {
			VStack(alignment: .leading, spacing: .small1) {
				VPair(
					heading: viewState.accountName,
					largeHeading: true,
					value: viewState.olympiaAccountType.label
				)

				VPair(
					heading: L10n.ImportOlympiaAccounts.AccountsToImport.olympiaAddressLabel,
					value: viewState.olympiaAddress.formatted(.default)
				)

				VPair(
					heading: L10n.ImportOlympiaAccounts.AccountsToImport.newAddressLabel,
					value: viewState.derivationPath.formatted(.default)
				)
			}

			Spacer(minLength: 0)
		}
		.padding(.vertical, .medium1)
		.padding(.horizontal, .medium2)
		.background(viewState.appearanceID.gradient)
		.cornerRadius(.small1)
	}

	struct VPair: View {
		let heading: String
		var largeHeading: Bool = false
		let value: String

		var body: some View {
			VStack(alignment: .leading, spacing: .small3) {
				Text(heading)
					.textStyle(largeHeading ? .secondaryHeader : .body2Link)
					.foregroundColor(.white)
				Text(value)
					.textStyle(.body2Regular)
					.foregroundColor(.app.gray4)
			}
		}
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
