
// MARK: - SelectInactiveAccountsToAdd.View

public extension SelectInactiveAccountsToAdd {
	struct ViewState: Equatable {
		let availableAccounts: [ChooseAccountsRow.State]
		let selectionRequirement: SelectionRequirement
		let selectedAccounts: [ChooseAccountsRow.State]?

		init(state: SelectInactiveAccountsToAdd.State) {
			let selectionRequirement = SelectionRequirement.atLeast(0)
			func map(_ account: Profile.Network.Account) -> ChooseAccountsRow.State {
				.init(account: account, mode: .checkmark)
			}
			self.availableAccounts = state.inactive.map(map)
			self.selectionRequirement = selectionRequirement
			self.selectedAccounts = state.selectedInactive.map(map)
		}
	}

	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<SelectInactiveAccountsToAdd>

		public init(store: StoreOf<SelectInactiveAccountsToAdd>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(
				store,
				observe: SelectInactiveAccountsToAdd.ViewState.init,
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
							ChooseAccountsRow.View(
								viewState: .init(state: item.value),
								isSelected: item.isSelected,
								action: item.action
							)
						}
					}
				}
			}
		}
	}
}
