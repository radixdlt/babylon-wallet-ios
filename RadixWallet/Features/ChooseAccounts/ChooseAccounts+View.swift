import ComposableArchitecture
import SwiftUI

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
			self.canCreateNewAccount = state.canCreateNewAccount

			// If the dApp is asking for exactly(1) account and user has only one account, pre-select it
			if case .permission = state.context,
			   selectionRequirement == .exactly(1),
			   availableAccounts.count == 1,
			   let account = availableAccounts.first
			{
				self.selectedAccounts = [account]
			} else {
				self.selectedAccounts = state.selectedAccounts
			}
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
			}
			.destinations(with: store)
		}
	}
}

private extension StoreOf<ChooseAccounts> {
	var destination: PresentationStoreOf<ChooseAccounts.Destination> {
		func scopeState(state: State) -> PresentationState<ChooseAccounts.Destination.State> {
			state.$destination
		}
		return scope(state: scopeState, action: Action.destination)
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<ChooseAccounts>) -> some View {
		let destinationStore = store.destination
		return sheet(
			store: destinationStore,
			state: /ChooseAccounts.Destination.State.createAccount,
			action: ChooseAccounts.Destination.Action.createAccount,
			content: { CreateAccountCoordinator.View(store: $0) }
		)
	}
}
