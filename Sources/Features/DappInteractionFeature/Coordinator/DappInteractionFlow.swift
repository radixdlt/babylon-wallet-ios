import FeaturePrelude
import TransactionSigningFeature

// MARK: - DappInteractionFlow
struct DappInteractionFlow: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		enum AnyInteractionItem: Sendable, Hashable {
			case remote(RemoteInteractionItem)
			case local(LocalInteractionItem)
		}

		enum AnyInteractionResponseItem: Sendable, Hashable {
			case remote(RemoteInteractionResponseItem)
			case local(LocalInteractionResponseItem)
		}

		typealias RemoteInteraction = P2P.FromDapp.WalletInteraction
		typealias RemoteInteractionItem = P2P.FromDapp.WalletInteraction.AnyInteractionItem
		typealias RemoteInteractionResponseItem = P2P.ToDapp.WalletInteractionSuccessResponse.AnyInteractionResponseItem

		enum LocalInteractionItem: Sendable, Hashable {
			case permissionRequested(Permission.State.PermissionKind)
		}

		enum LocalInteractionResponseItem: Sendable, Hashable {
			case permissionGranted
		}

		let dappMetadata: DappMetadata
		let remoteInteraction: RemoteInteraction

		let interactionItems: NonEmpty<OrderedSet<AnyInteractionItem>>
		var responseItems: OrderedDictionary<AnyInteractionItem, AnyInteractionResponseItem> = [:]

		var root: Destinations.State?
		@NavigationStateOf<Destinations>
		var path: NavigationState<Destinations.State>.Path

		init?(
			dappMetadata: DappMetadata,
			interaction remoteInteraction: RemoteInteraction
		) {
			self.dappMetadata = dappMetadata
			self.remoteInteraction = remoteInteraction

			if let interactionItems = NonEmpty(rawValue: OrderedSet<AnyInteractionItem>(for: remoteInteraction.erasedItems)) {
				self.interactionItems = interactionItems
				self.root = Destinations.State(for: interactionItems.first, in: remoteInteraction, with: dappMetadata)
			} else {
				return nil
			}
		}
	}

	enum ViewAction: Sendable, Equatable {
		case appeared
		case closeButtonTapped
		case backButtonTapped
	}

	enum ChildAction: Sendable, Equatable {
		case root(Destinations.Action)
		case path(NavigationActionOf<Destinations>)
	}

	enum DelegateAction: Sendable, Equatable {
		case dismiss
	}

	struct Destinations: Sendable, ReducerProtocol {
		typealias StateWithRelayedInteractionItem<MainState> = RelayState<DappInteractionFlow.State.AnyInteractionItem, MainState>
		typealias ActionWithRelayedInteractionItem<MainAction> = RelayAction<DappInteractionFlow.State.AnyInteractionItem, MainAction>

		enum State: Sendable, Hashable {
			case login(StateWithRelayedInteractionItem<LoginRequest.State>)
			case permission(StateWithRelayedInteractionItem<Permission.State>)
			case chooseAccounts(StateWithRelayedInteractionItem<ChooseAccounts.State>)
			case signAndSubmitTransaction(StateWithRelayedInteractionItem<TransactionSigning.State>)
		}

		enum Action: Sendable, Equatable {
			case login(ActionWithRelayedInteractionItem<LoginRequest.Action>)
			case permission(ActionWithRelayedInteractionItem<Permission.Action>)
			case chooseAccounts(ActionWithRelayedInteractionItem<ChooseAccounts.Action>)
			case signAndSubmitTransaction(ActionWithRelayedInteractionItem<TransactionSigning.Action>)
		}

		var body: some ReducerProtocolOf<Self> {
			Scope(state: /State.login, action: /Action.login) {
				Relay { LoginRequest() }
			}
			Scope(state: /State.permission, action: /Action.permission) {
				Relay { Permission() }
			}
			Scope(state: /State.chooseAccounts, action: /Action.chooseAccounts) {
				Relay { ChooseAccounts() }
			}
			Scope(state: /State.signAndSubmitTransaction, action: /Action.signAndSubmitTransaction) {
				Relay { TransactionSigning() }
			}
		}
	}

	var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.ifLet(\.root, action: /Action.child .. ChildAction.root) {
				Destinations()
			}
			.navigationDestination(\.$path, action: /Action.child .. ChildAction.path) {
				Destinations()
			}
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			// TODO: handle usePersona
			return continueEffect(for: &state)
		case .closeButtonTapped:
			return .send(.delegate(.dismiss))
		case .backButtonTapped:
			return goBackEffect(for: &state)
		}
	}

	func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case
			let .root(.login(.relay(item, .delegate(.continueButtonTapped(persona, authorizedPersona))))),
			let .path(.element(_, .login(.relay(item, .delegate(.continueButtonTapped(persona, authorizedPersona)))))):
			let responseItem: State.AnyInteractionResponseItem = .remote(.auth(.login(.withoutChallenge(.init(
				identityAddress: persona.address.address
			)))))
			state.responseItems[item] = responseItem
			return continueEffect(for: &state)
		case
			let .root(.permission(.relay(item, .delegate(.continueButtonTapped)))),
			let .path(.element(_, .permission(.relay(item, .delegate(.continueButtonTapped))))):
			let responseItem: State.AnyInteractionResponseItem = .local(.permissionGranted)
			state.responseItems[item] = responseItem
			return continueEffect(for: &state)
		case
			let .root(.chooseAccounts(.relay(item, .delegate(.continueButtonTapped(accounts, accessKind))))),
			let .path(.element(_, .chooseAccounts(.relay(item, .delegate(.continueButtonTapped(accounts, accessKind)))))):
			setAccountsResponse(to: item, accounts, accessKind: accessKind, into: &state)
			return continueEffect(for: &state)
		default:
			return .none
		}
	}

	func setAccountsResponse(
		to item: State.AnyInteractionItem,
		_ accounts: some Collection<OnNetwork.Account>,
		accessKind: ChooseAccounts.State.AccessKind,
		into state: inout State
	) {
		let responseItem: State.AnyInteractionResponseItem = {
			switch accessKind {
			case .ongoing:
				return .remote(.ongoingAccounts(.withoutProof(.init(accounts: accounts.map(P2P.ToDapp.WalletAccount.init)))))
			case .oneTime:
				return .remote(.oneTimeAccounts(.withoutProof(.init(accounts: accounts.map(P2P.ToDapp.WalletAccount.init)))))
			}
		}()
		state.responseItems[item] = responseItem
	}

	func continueEffect(for state: inout State) -> EffectTask<Action> {
		if
			let nextRequest = state.interactionItems.first(where: { state.responseItems[$0] == nil }),
			let destination = Destinations.State(for: nextRequest, in: state.remoteInteraction, with: state.dappMetadata)
		{
			if state.root == nil {
				state.root = destination
			} else if state.path.last != destination {
				state.path.append(destination)
			}
			return .none
		} else {
			return .run { _ in } // TODO: flow is finished, submit response!
		}
	}

	func goBackEffect(for state: inout State) -> EffectTask<Action> {
		state.responseItems.removeLast()
		state.path.removeLast()
		return .none
	}
}

extension OrderedSet<DappInteractionFlow.State.AnyInteractionItem> {
	init(for remoteInteractionItems: some Collection<DappInteractionFlow.State.RemoteInteractionItem>) {
		self.init(
			remoteInteractionItems
				.sorted(by: { $0.priority < $1.priority })
				.reduce(into: []) { items, currentItem in
					switch currentItem {
					case .auth:
						items.append(.remote(currentItem))
					case let .ongoingAccounts(item):
						items.append(.local(.permissionRequested(.accounts(item.numberOfAccounts))))
						items.append(.remote(currentItem))
					case .oneTimeAccounts:
						items.append(.remote(currentItem))
					case .send:
						items.append(.remote(currentItem))
					}
				}
		)
	}
}

extension DappInteractionFlow.Destinations.State {
	init?(
		for anyItem: DappInteractionFlow.State.AnyInteractionItem,
		in interaction: DappInteractionFlow.State.RemoteInteraction,
		with dappMetadata: DappMetadata
	) {
		switch anyItem {
		case .remote(.auth(.usePersona)):
			return nil
		case .remote(.auth(.login(_))): // TODO: bind to item when implementing auth challenge
			self = .login(.relayed(anyItem, with: .init(
				dappDefinitionAddress: interaction.metadata.dAppDefinitionAddress,
				dappMetadata: dappMetadata
			)))
		case let .local(.permissionRequested(permissionKind)):
			self = .permission(.relayed(anyItem, with: .init(
				permissionKind: permissionKind,
				dappMetadata: dappMetadata
			)))
		case let .remote(.ongoingAccounts(item)):
			self = .chooseAccounts(.relayed(anyItem, with: .init(
				accessKind: .ongoing,
				dappDefinitionAddress: interaction.metadata.dAppDefinitionAddress,
				dappMetadata: dappMetadata,
				numberOfAccounts: item.numberOfAccounts
			)))
		case let .remote(.oneTimeAccounts(item)):
			self = .chooseAccounts(.relayed(anyItem, with: .init(
				accessKind: .oneTime,
				dappDefinitionAddress: interaction.metadata.dAppDefinitionAddress,
				dappMetadata: dappMetadata,
				numberOfAccounts: item.numberOfAccounts
			)))
		case let .remote(.send(item)):
			self = .signAndSubmitTransaction(.relayed(anyItem, with: .init(
				transactionManifestWithoutLockFee: item.transactionManifest
			)))
		}
	}
}
