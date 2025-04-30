
// MARK: - SelectInactiveAccountsToAdd.View

extension SelectInactiveAccountsToAdd {
	struct ViewState: Equatable {
		let availableAccounts: [ChooseAccountsRow.State]
		let selectionRequirement: SelectionRequirement
		let selectedAccounts: [ChooseAccountsRow.State]?

		init(state: SelectInactiveAccountsToAdd.State) {
			let selectionRequirement = SelectionRequirement.atLeast(0)
			func rowState(_ account: Account) -> ChooseAccountsRow.State {
				.init(account: account, mode: .checkmark)
			}
			self.availableAccounts = state.inactive.map(rowState)
			self.selectionRequirement = selectionRequirement
			self.selectedAccounts = state.selectedInactive.map(rowState)
		}
	}

	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<SelectInactiveAccountsToAdd>

		init(store: StoreOf<SelectInactiveAccountsToAdd>) {
			self.store = store
		}

		var body: some SwiftUI.View {
			WithViewStore(
				store,
				observe: SelectInactiveAccountsToAdd.ViewState.init,
				send: { .view($0) }
			) { viewStore in
				ScrollView {
					VStack(spacing: 0) {
						Text(L10n.AccountRecoveryScan.SelectInactiveAccounts.Header.title)
							.multilineTextAlignment(.center)
							.textStyle(.sheetTitle)
							.foregroundColor(.primaryText)
							.padding(.top, .medium3)
							.padding(.horizontal, .medium1)
							.padding(.bottom, .medium1)

						Text(L10n.AccountRecoveryScan.SelectInactiveAccounts.Header.subtitle)
							.multilineTextAlignment(.center)
							.textStyle(.body1Regular)
							.foregroundColor(.primaryText)
							.padding(.horizontal, .large2)
							.padding(.bottom, .medium1)

						VStack(spacing: .medium3) {
							Selection(
								viewStore.binding(
									get: \.selectedAccounts,
									send: { .selectedAccountsChanged($0) }
								),
								from: viewStore.availableAccounts,
								requiring: viewStore.selectionRequirement
							) { item in
								ChooseAccountsRow.View(
									viewState: .init(state: item.value),
									isSelected: item.isSelected,
									showName: false,
									action: item.action
								)
							}
						}
						.padding(.horizontal, .medium3)
					}

					Spacer(minLength: 0)
				}
				.footer {
					Button(L10n.AccountRecoveryScan.SelectInactiveAccounts.continueButton) {
						store.send(.view(.doneTapped))
					}
					.buttonStyle(.primaryRectangular)
				}
				.navigationBarBackButtonHidden()
				.toolbar {
					ToolbarItem(placement: .navigationBarLeading) {
						BackButton {
							viewStore.send(.backButtonTapped, animation: .default)
						}
					}
				}
			}
		}
	}
}
