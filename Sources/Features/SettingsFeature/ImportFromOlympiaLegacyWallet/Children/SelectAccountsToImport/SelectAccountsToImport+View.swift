import AccountsClient
import FeaturePrelude

extension SelectAccountsToImport.State {
	var viewState: SelectAccountsToImport.ViewState {
		.init(
			availableAccounts: availableAccounts.elements,
			selectionRequirement: selectionRequirement,
			selectedAccounts: selectedAccounts
		)
	}
}

// MARK: - SelectAccountsToImport.View
extension SelectAccountsToImport {
	public struct ViewState: Equatable {
		let availableAccounts: [OlympiaAccountToMigrate]
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
								isSelected: item.isSelected,
								action: item.action
							)
						}
					}

					.padding(.horizontal, .medium1)
					.padding(.bottom, .medium2)
				}
				.footer {
					WithControlRequirements(
						viewStore.selectedAccounts,
						forAction: { viewStore.send(.continueButtonTapped($0)) }
					) { action in
						Button("Import Olympia Accounts", action: action)
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
		let xrdBalance: BigDecimal

		init(state olympiaAccount: OlympiaAccountToMigrate) {
			accountName = olympiaAccount.displayName?.rawValue ?? "NOT NAMED"
//			olympiaAddress = AddressView.ViewState(address: olympiaAccount.address.address.rawValue)
			olympiaAddress = olympiaAccount.address.address.rawValue
			appearanceID = .fromIndex(Int(olympiaAccount.addressIndex))
			derivationPath = olympiaAccount.path.derivationPath
			xrdBalance = olympiaAccount.xrd
		}
	}

	@MainActor
	struct View: SwiftUI.View {
		let viewState: ViewState
		let isSelected: Bool
		let action: () -> Void

		var body: some SwiftUI.View {
			Button(action: action) {
				HStack {
					VStack(alignment: .leading, spacing: .medium2) {
						HPair(label: "Name", item: viewState.accountName)
						//                        HPair(label: "Address", item: viewState.olympiaAddress)
						VStack(alignment: .leading, spacing: .small3) {
							Group {
								Text("Olympia address")
									.textStyle(.body2Header)

								Text(viewState.olympiaAddress)
									.textStyle(.monospace)
									.frame(maxWidth: .infinity, alignment: .leading)
							}
							.foregroundColor(.app.white)
						}
						HPair(label: "XRD", item: viewState.xrdBalance.format())
						HPair(label: "Path", item: viewState.derivationPath)
					}
					Spacer()

					CheckmarkView(
						appearance: .light,
						isChecked: isSelected
					)
				}
				.padding(.medium1)
				.background(
					viewState.appearanceID.gradient
						.brightness(isSelected ? -0.1 : 0)
				)
				.cornerRadius(.small1)
			}
			.buttonStyle(.inert)
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - SelectAccountsToImport_Preview
struct SelectAccountsToImport_Preview: PreviewProvider {
	static var previews: some View {
		SelectAccountsToImport.View(
			store: .init(
				initialState: .previewValue,
				reducer: SelectAccountsToImport()
			)
		)
	}
}

extension [OlympiaAccountToMigrate] {
	public static let previewValue: Self = OrderedSet<UncheckedImportedOlympiaWalletPayload>.previewValue.flatMap { try! $0.accountsToImport() }
}

extension SelectAccountsToImport.State {
	public static let previewValue = Self(
		scannedAccounts: .init(rawValue: .init(uncheckedUniqueElements: Array<OlympiaAccountToMigrate>.previewValue))!
	)
}
#endif
