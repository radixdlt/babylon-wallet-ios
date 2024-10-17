import ComposableArchitecture
import SwiftUI

// MARK: - AccountsToImport.View
extension AccountsToImport {
	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<AccountsToImport>

		init(store: StoreOf<AccountsToImport>) {
			self.store = store
		}

		var body: some SwiftUI.View {
			WithViewStore(store, observe: { $0 }, send: { .view($0) }) { viewStore in
				ScrollView {
					VStack(spacing: .medium3) {
						Group {
							Text(L10n.ImportOlympiaAccounts.AccountsToImport.title)
								.textStyle(.sheetTitle)
								.padding(.horizontal, .large2)

							Text(L10n.ImportOlympiaAccounts.AccountsToImport.subtitle)
								.textStyle(.body1Regular)
								.padding(.horizontal, .large2)
						}
						.foregroundColor(.app.gray1)
						.multilineTextAlignment(.center)

						ForEach(viewStore.scannedAccounts) { account in
							AccountView(viewState: account)
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
				.onAppear {
					viewStore.send(.appeared)
				}
			}
		}
	}
}

// MARK: - AccountView
struct AccountView: View {
	typealias ViewState = ImportOlympiaWalletCoordinator.MigratableAccount

	let viewState: ViewState

	init(viewState: ViewState) {
		self.viewState = viewState
	}

	var body: some View {
		HStack(spacing: 0) {
			VStack(alignment: .leading, spacing: .small1) {
				VPair(
					heading: viewState.accountName ?? L10n.ImportOlympiaAccounts.AccountsToImport.unnamed,
					value: viewState.olympiaAccountType.label,
					large: true
				)

				VPair(
					heading: L10n.ImportOlympiaAccounts.AccountsToImport.olympiaAddressLabel,
					value: viewState.olympiaAddress.formatted()
				)

				VPair(
					heading: L10n.ImportOlympiaAccounts.AccountsToImport.newAddressLabel,
					value: viewState.babylonAddress.formatted()
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
		let value: String
		var large: Bool = false

		var body: some View {
			VStack(alignment: .leading, spacing: large ? .small2 : .small3) {
				Text(heading)
					.textStyle(large ? .secondaryHeader : .body2Link)
					.foregroundColor(.white)

				Text(value)
					.textStyle(.body2Regular)
					.foregroundColor(.app.gray4)
			}
			.padding(.bottom, large ? .small3 : 0)
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
			L10n.ImportOlympiaAccounts.AccountsToImport.legacyAccount
		case .hardware:
			L10n.ImportOlympiaAccounts.AccountsToImport.ledgerAccount
		}
	}
}
