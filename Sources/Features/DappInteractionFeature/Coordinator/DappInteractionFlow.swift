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
			case permissionGranted(Permission.State.PermissionKind)
		}

		let dappMetadata: DappMetadata
		let remoteInteraction: RemoteInteraction

		let interactionItems: NonEmpty<OrderedSet<AnyInteractionItem>>
		var responseItems: [AnyInteractionItem: AnyInteractionResponseItem] = [:]

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
		enum State: Sendable, Hashable {
			case login(LoginRequest.State)
			case permission(Permission.State)
			case chooseAccounts(ChooseAccounts.State)
			case signAndSubmitTransaction(TransactionSigning.State)
		}

		enum Action: Sendable, Equatable {
			case login(LoginRequest.Action)
			case permission(Permission.Action)
			case chooseAccounts(ChooseAccounts.Action)
			case signAndSubmitTransaction(TransactionSigning.Action)
		}

		var body: some ReducerProtocolOf<Self> {
			Scope(state: /State.login, action: /Action.login) {
				LoginRequest()
			}
			Scope(state: /State.permission, action: /Action.permission) {
				Permission()
			}
			Scope(state: /State.chooseAccounts, action: /Action.chooseAccounts) {
				ChooseAccounts()
			}
			Scope(state: /State.signAndSubmitTransaction, action: /Action.signAndSubmitTransaction) {
				TransactionSigning()
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
			return .none // TODO: handle current case (in case it's usePersona)
		case .closeButtonTapped:
			return .send(.delegate(.dismiss))
		case .backButtonTapped:
			_ = state.path.popLast()
			return .none
		}
	}

	func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case
			let .root(.login(.delegate(.continueButtonTapped(persona, authorizedPersona)))),
			let .path(.element(_, .login(.delegate(.continueButtonTapped(persona, authorizedPersona))))):
			state.path.append(.chooseAccounts(.previewValue)) // TODO: proper handling
			return .none
		default:
			return .none
		}
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
		for item: DappInteractionFlow.State.AnyInteractionItem,
		in interaction: DappInteractionFlow.State.RemoteInteraction,
		with dappMetadata: DappMetadata
	) {
		switch item {
		case .remote(.auth(.usePersona)):
			return nil
		case .remote(.auth(.login(_))): // TODO: bind to item when implementing auth challenge
			self = .login(.init(
				dappDefinitionAddress: interaction.metadata.dAppDefinitionAddress,
				dappMetadata: dappMetadata
			))
		case let .local(.permissionRequested(permissionKind)):
			self = .permission(.init(
				permissionKind: permissionKind,
				dappMetadata: dappMetadata
			))
		case let .remote(.ongoingAccounts(item)):
			self = .chooseAccounts(.init(
				accessKind: .ongoing,
				dappDefinitionAddress: interaction.metadata.dAppDefinitionAddress,
				dappMetadata: dappMetadata,
				numberOfAccounts: item.numberOfAccounts
			))
		case let .remote(.oneTimeAccounts(item)):
			self = .chooseAccounts(.init(
				accessKind: .oneTime,
				dappDefinitionAddress: interaction.metadata.dAppDefinitionAddress,
				dappMetadata: dappMetadata,
				numberOfAccounts: item.numberOfAccounts
			))
		case let .remote(.send(item)):
			self = .signAndSubmitTransaction(.init(
				transactionManifestWithoutLockFee: item.transactionManifest
			))
		}
	}
}
