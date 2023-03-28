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
		let accountAddress: AddressView.ViewState

		init(state olympiaAccount: OlympiaAccountToMigrate) {
			accountName = olympiaAccount.displayName?.rawValue ?? "NOT NAMED"
			accountAddress = AddressView.ViewState(address: olympiaAccount.address.address.rawValue)
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
					VStack(alignment: .leading, spacing: .medium3) {
						Text(viewState.accountName)
							.foregroundColor(.app.white)
							.textStyle(.body1Header)

						AddressView(viewState.accountAddress, copyAddressAction: .none)
							.foregroundColor(.app.white.opacity(0.8))
							.textStyle(.body2HighImportance)
					}

					Spacer()

					CheckmarkView(
						appearance: .light,
						isChecked: isSelected
					)
				}
				.padding(.medium1)
				.background(
					Color.yellow
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

extension SelectAccountsToImport.State {
	public static let previewValue = Self(scannedAccounts: .init(rawValue: .init(uncheckedUniqueElements: [OlympiaAccountToMigrate.previewValue]))!)
}
#endif
