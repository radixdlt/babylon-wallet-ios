import FeaturePrelude
import ImportLegacyWalletClient

extension SelectAccountsToImport.State {
	var viewState: SelectAccountsToImport.ViewState {
		.init(
			availableAccounts: availableAccounts.elements,
			alreadyImported: alreadyImported,
			selectionRequirement: selectionRequirement,
			selectedAccounts: selectedAccounts
		)
	}
}

// MARK: - SelectAccountsToImport.View
extension SelectAccountsToImport {
	public struct ViewState: Equatable {
		let availableAccounts: [OlympiaAccountToMigrate]
		let alreadyImported: Set<OlympiaAccountToMigrate.ID>
		let selectionRequirement: SelectionRequirement
		let selectedAccounts: [OlympiaAccountToMigrate]?
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<SelectAccountsToImport>

		public init(store: StoreOf<SelectAccountsToImport>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(
				store,
				observe: { $0.viewState },
				send: { .view($0) }
			) { viewStore in
				ScrollView {
					VStack(spacing: .small1) {
						Selection(
							viewStore.binding(
								get: \.selectedAccounts,
								send: { .selectedAccountsChanged($0) }
							),
							from: viewStore.availableAccounts,
							requiring: viewStore.selectionRequirement
						) { item in
							SelectAccountsToImportRow.View(
								viewState: .init(state: item.value),
								isAlreadyImported: viewStore.alreadyImported.contains(item.value.id),
								isSelected: item.isSelected,
								action: item.action
							)
						}
					}

					.padding(.horizontal, .medium1)
					.padding(.bottom, .medium2)
				}
				.footer {
					VStack {
						Button(L10n.ImportLegacyWallet.SelectAccountsToImport.deselectAll) {
							viewStore.send(.deselectAll)
						}
						.buttonStyle(.secondaryRectangular(shouldExpand: true))

						Button(L10n.ImportLegacyWallet.SelectAccountsToImport.selectAllNonImported) {
							viewStore.send(.selectAllNonImported)
						}
						.buttonStyle(.secondaryRectangular(shouldExpand: true))
					}

					WithControlRequirements(
						viewStore.selectedAccounts,
						forAction: { viewStore.send(.continueButtonTapped($0)) }
					) { action in
						let numberOfSelectedAccounts = viewStore.selectedAccounts?.count ?? 0
						let title: String = {
							if numberOfSelectedAccounts == 0 {
								return L10n.ImportLegacyWallet.SelectAccountsToImport.importZeroAccounts
							} else if numberOfSelectedAccounts == 1 {
								return L10n.ImportLegacyWallet.SelectAccountsToImport.importOneAcccount
							} else {
								return L10n.ImportLegacyWallet.SelectAccountsToImport.importManyAccounts(numberOfSelectedAccounts)
							}
						}()
						Button(title, action: action)
							.buttonStyle(.primaryRectangular)
					}
				}
				.onAppear {
					viewStore.send(.appeared)
				}
			}
		}
	}
}

import EngineToolkit

// MARK: - SelectAccountsToImportRow
enum SelectAccountsToImportRow {
	struct ViewState: Equatable {
		let accountName: String
		let olympiaAddress: String
		let appearanceID: Profile.Network.Account.AppearanceID
		let derivationPath: String
		let olympiaAccountType: Olympia.AccountType

		init(state olympiaAccount: OlympiaAccountToMigrate) {
			accountName = olympiaAccount.displayName?.rawValue ?? L10n.ImportLegacyWallet.SelectAccountsToImport.unnamed

			olympiaAddress = olympiaAccount.address.address.rawValue
			appearanceID = .fromIndex(Int(olympiaAccount.addressIndex))
			derivationPath = olympiaAccount.path.derivationPath
			olympiaAccountType = olympiaAccount.accountType
		}
	}

	@MainActor
	struct View: SwiftUI.View {
		let viewState: ViewState
		let isAlreadyImported: Bool
		let isSelected: Bool
		let action: () -> Void

		var body: some SwiftUI.View {
			if isAlreadyImported {
				label
			} else {
				Button(action: action) {
					label
				}
				.buttonStyle(.inert)
			}
		}

		private var label: some SwiftUI.View {
			HStack {
				VStack(alignment: .leading, spacing: .medium2) {
					if isAlreadyImported {
						Text("Already imported")
							.textStyle(.body1HighImportance)
					}

					HPair(label: L10n.ImportLegacyWallet.SelectAccountsToImport.accountType, item: String(describing: viewState.olympiaAccountType))

					HPair(label: L10n.ImportLegacyWallet.SelectAccountsToImport.name, item: viewState.accountName)

					VStack(alignment: .leading, spacing: .small3) {
						Text(L10n.ImportLegacyWallet.SelectAccountsToImport.olympiaAddress)
							.textStyle(.body2Header)

						Text(viewState.olympiaAddress)
							.textStyle(.monospace)
							.frame(maxWidth: .infinity, alignment: .leading)
					}
					HPair(label: L10n.ImportLegacyWallet.SelectAccountsToImport.derivationPath, item: viewState.derivationPath)
				}
				.foregroundColor(.app.white)

				Spacer()

				if !isAlreadyImported {
					CheckmarkView(
						appearance: .light,
						isChecked: isSelected
					)
				}
			}
			.padding(.medium1)
			.background(
				labelBackground
			)
			.cornerRadius(.small1)
		}

		@ViewBuilder
		private var labelBackground: some SwiftUI.View {
			if !isAlreadyImported {
				viewState.appearanceID.gradient
					.brightness(isSelected ? -0.1 : 0)
			} else {
				Color.app.gray3
			}
		}
	}
}

// #if DEBUG
// import SwiftUI // NB: necessary for previews to appear
//
//// MARK: - SelectAccountsToImport_Preview
// struct SelectAccountsToImport_Preview: PreviewProvider {
//	static var previews: some View {
//		SelectAccountsToImport.View(
//			store: .init(
//				initialState: .previewValue,
//				reducer: SelectAccountsToImport()
//			)
//		)
//	}
// }
//
////extension [OlympiaAccountToMigrate] {
////	public static let previewValue: Self = OrderedSet<UncheckedImportedOlympiaWalletPayload>.mocks.flatMap { try! $0.accountsToImport() }
////}
//
// extension SelectAccountsToImport.State {
//	public static let previewValue = Self(
//		scannedAccounts: .init(rawValue: .init(uncheckedUniqueElements: Array<OlympiaAccountToMigrate>.previewValue))!
//	)
// }
// #endif
