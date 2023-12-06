
// MARK: - SelectInactiveAccountsToAdd.View

public extension SelectInactiveAccountsToAdd {
	struct ViewState: Equatable {
		let availableAccounts: [ChooseAccountsRow.State]
		let selectionRequirement: SelectionRequirement
		let selectedAccounts: [ChooseAccountsRow.State]?

		init(state: SelectInactiveAccountsToAdd.State) {
			let selectionRequirement = SelectionRequirement.atLeast(0)
			func rowState(_ account: Profile.Network.Account) -> ChooseAccountsRow.State {
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

		public init(store: StoreOf<SelectInactiveAccountsToAdd>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(
				store,
				observe: SelectInactiveAccountsToAdd.ViewState.init,
				send: { .view($0) }
			) { viewStore in
				VStack(spacing: 0) {
					Text("Add Inactive Accounts?") // FIXME: Strings
						.multilineTextAlignment(.center)
						.textStyle(.sheetTitle)
						.foregroundColor(.app.gray1)
						.padding(.top, .medium3)
						.padding(.horizontal, .medium1)
						.padding(.bottom, .medium3)

					// FIXME: Strings
					Text("These Accounts were never used, but you *may* have created them. Check any addresses that you wish to keep:")
						.multilineTextAlignment(.center)
						.textStyle(.body1Regular)
						.foregroundColor(.app.gray1)
						.padding(.horizontal, .large2)
						.padding(.bottom, .medium1)

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
					Button("Continue") { // FIXME: Strings
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
