import AccountsClient
import CreateEntityFeature
import FactorSourcesClient
import FeaturePrelude
import ROLAClient
import SigningFeature

// MARK: - _ChooseAccounts
struct _ChooseAccounts: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		let selectionRequirement: SelectionRequirement
		var availableAccounts: IdentifiedArrayOf<Profile.Network.Account>
		var selectedAccounts: [ChooseAccountsRow.State]?
		@PresentationState
		var destination: Destinations.State?

		init(
			selectionRequirement: SelectionRequirement,
			availableAccounts: IdentifiedArrayOf<Profile.Network.Account> = [],
			selectedAccounts: [ChooseAccountsRow.State]? = nil
		) {
			self.selectionRequirement = selectionRequirement
			self.availableAccounts = availableAccounts
			self.selectedAccounts = selectedAccounts
		}
	}

	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.accountsClient) var accountsClient

	enum ChildAction: Sendable, Equatable {
		case destination(PresentationAction<Destinations.Action>)
	}

	enum InternalAction: Sendable, Equatable {
		case loadAccountsResult(TaskResult<Profile.Network.Accounts>)
	}

	enum ViewAction: Sendable, Equatable {
		case appeared
		case createAccountButtonTapped
		case selectedAccountsChanged([ChooseAccountsRow.State]?)
	}

	struct Destinations: Sendable, ReducerProtocol {
		enum State: Sendable, Hashable {
			case createAccount(CreateAccountCoordinator.State)
		}

		enum Action: Sendable, Equatable {
			case createAccount(CreateAccountCoordinator.Action)
		}

		var body: some ReducerProtocolOf<Self> {
			Scope(state: /State.createAccount, action: /Action.createAccount) {
				CreateAccountCoordinator()
			}
		}
	}

	var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.ifLet(\.$destination, action: /Action.child .. ChildAction.destination) {
				Destinations()
			}
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return .run { send in
				await send(.internal(.loadAccountsResult(TaskResult {
					try await accountsClient.getAccountsOnCurrentNetwork()
				})))
			}

		case .createAccountButtonTapped:
			state.destination = .createAccount(.init(config: .init(
				purpose: .newAccountDuringDappInteraction
			), displayIntroduction: { _ in false }))
			return .none

		case let .selectedAccountsChanged(selectedAccounts):
			state.selectedAccounts = selectedAccounts
			return .none
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .loadAccountsResult(.success(accounts)):
			state.availableAccounts = .init(uniqueElements: accounts)
			return .none

		case let .loadAccountsResult(.failure(error)):
			errorQueue.schedule(error)
			return .none
		}
	}

	func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case .destination(.presented(.createAccount(.delegate(.completed)))):
			return .run { send in
				await send(.internal(.loadAccountsResult(TaskResult {
					try await accountsClient.getAccountsOnCurrentNetwork()
				})))
			}

		default:
			return .none
		}
	}
}

import CreateEntityFeature
import FeaturePrelude
import SigningFeature

// MARK: - ChooseAccounts.View
extension _ChooseAccounts {
	struct ViewState: Equatable {
		let availableAccounts: [ChooseAccountsRow.State]
		let selectionRequirement: SelectionRequirement
		let selectedAccounts: [ChooseAccountsRow.State]?

		init(state: _ChooseAccounts.State) {
			let selectionRequirement = state.selectionRequirement

			self.availableAccounts = state.availableAccounts.map { account in
				ChooseAccountsRow.State(
					account: account,
					mode: selectionRequirement == .exactly(1) ? .radioButton : .checkmark
				)
			}
			self.selectionRequirement = selectionRequirement
			self.selectedAccounts = state.selectedAccounts
		}
	}

	@MainActor
	struct View: SwiftUI.View {
		let store: StoreOf<_ChooseAccounts>

		var body: some SwiftUI.View {
			WithViewStore(
				store,
				observe: _ChooseAccounts.ViewState.init,
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

						Button(L10n.DAppRequest.ChooseAccounts.createNewAccount) {
							viewStore.send(.createAccountButtonTapped)
						}
						.buttonStyle(.secondaryRectangular(shouldExpand: false))
					}
					.padding(.horizontal, .medium1)
					.padding(.bottom, .medium2)
				}
				.onAppear {
					viewStore.send(.appeared)
				}
				.sheet(
					store: store.scope(state: \.$destination, action: { .child(.destination($0)) }),
					state: /_ChooseAccounts.Destinations.State.createAccount,
					action: _ChooseAccounts.Destinations.Action.createAccount,
					content: { CreateAccountCoordinator.View(store: $0) }
				)
			}
		}
	}
}
