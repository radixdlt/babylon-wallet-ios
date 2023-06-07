import CreateAccountFeature
import FeaturePrelude

// MARK: - ChooseAccounts.View
extension ChooseAccounts {
	public struct ViewState: Equatable {
		let availableAccounts: [ChooseAccountsRow.State]
		let selectionRequirement: SelectionRequirement
		let selectedAccounts: [ChooseAccountsRow.State]?
		let canCreateNewAccount: Bool

		init(state: ChooseAccounts.State) {
			let selectionRequirement = state.selectionRequirement

			self.availableAccounts = state.availableAccounts.map { account in
				ChooseAccountsRow.State(
					account: account,
					mode: selectionRequirement == .exactly(1) ? .radioButton : .checkmark
				)
			}
			self.selectionRequirement = selectionRequirement
			self.selectedAccounts = state.selectedAccounts
			self.canCreateNewAccount = state.canCreateNewAccount
		}
	}

	@MainActor
	public struct View: SwiftUI.View {
		public let store: StoreOf<ChooseAccounts>

		public init(store: StoreOf<ChooseAccounts>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(
				store,
				observe: ChooseAccounts.ViewState.init,
				send: { .view($0) }
			) { viewStore in
				ScrollView {
					VStack(spacing: .medium2) {
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

						if viewStore.canCreateNewAccount {
							Button(L10n.DAppRequest.ChooseAccounts.createNewAccount) {
								viewStore.send(.createAccountButtonTapped)
							}
							.buttonStyle(.secondaryRectangular(shouldExpand: false))
						}
					}
				}
				.onAppear {
					viewStore.send(.appeared)
				}
				.sheet(
					store: store.scope(state: \.$destination, action: { .child(.destination($0)) }),
					state: /ChooseAccounts.Destinations.State.createAccount,
					action: ChooseAccounts.Destinations.Action.createAccount,
					content: { CreateAccountCoordinator.View(store: $0) }
				)
			}
		}
	}
}
