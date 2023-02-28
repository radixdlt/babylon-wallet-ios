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
		var persona: OnNetwork.Persona?
		var authorizedDapp: OnNetwork.AuthorizedDapp?
		var authorizedPersona: OnNetwork.AuthorizedDapp.AuthorizedPersonaSimple?

		let interactionItems: NonEmpty<OrderedSet<AnyInteractionItem>>
		var responseItems: OrderedDictionary<AnyInteractionItem, AnyInteractionResponseItem> = [:]

		@PresentationState
		var personaNotFoundErrorAlert: AlertState<ViewAction.PersonaNotFoundErrorAlertAction>? = nil

		var root: Destinations.State?
		@NavigationStateOf<Destinations>
		var path

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
		case personaNotFoundErrorAlert(PresentationAction<AlertState<PersonaNotFoundErrorAlertAction>, PersonaNotFoundErrorAlertAction>)

		enum PersonaNotFoundErrorAlertAction: Sendable, Equatable {
			case cancelButtonTapped
		}
	}

	enum InternalAction: Sendable, Equatable {
		case usePersona(
			P2P.FromDapp.WalletInteraction.AuthUsePersonaRequestItem,
			OnNetwork.Persona,
			OnNetwork.AuthorizedDapp?,
			OnNetwork.AuthorizedDapp.AuthorizedPersonaSimple?
		)
		case presentPersonaNotFoundErrorAlert(reason: String)
		case autofillOngoingResponseItemsIfPossible(AutofillOngoingResponseItemsPayload)

		struct AutofillOngoingResponseItemsPayload: Sendable, Equatable {
			struct AccountsPayload: Sendable, Equatable {
				var requestItem: DappInteractionFlow.State.AnyInteractionItem
				var accounts: [OnNetwork.Account]
				var numberOfAccountsRequested: DappInteraction.NumberOfAccounts
			}

			var accountsPayload: AccountsPayload?
		}
	}

	enum ChildAction: Sendable, Equatable {
		case root(Destinations.Action)
		case path(NavigationActionOf<Destinations>)
	}

	enum DelegateAction: Sendable, Equatable {
		case dismiss(P2P.ToDapp.WalletInteractionFailureResponse)
		case submit(P2P.ToDapp.WalletInteractionSuccessResponse, DappMetadata)
	}

	struct Destinations: Sendable, ReducerProtocol {
		typealias State = RelayState<DappInteractionFlow.State.AnyInteractionItem, MainState>
		typealias Action = RelayAction<DappInteractionFlow.State.AnyInteractionItem, MainAction>

		enum MainState: Sendable, Hashable {
			case login(Login.State)
			case permission(Permission.State)
			case chooseAccounts(ChooseAccounts.State)
			case signAndSubmitTransaction(TransactionSigning.State)
		}

		enum MainAction: Sendable, Equatable {
			case login(Login.Action)
			case permission(Permission.Action)
			case chooseAccounts(ChooseAccounts.Action)
			case signAndSubmitTransaction(TransactionSigning.Action)
		}

		var body: some ReducerProtocolOf<Self> {
			Relay {
				Scope(state: /MainState.login, action: /MainAction.login) {
					Login()
				}
				Scope(state: /MainState.permission, action: /MainAction.permission) {
					Permission()
				}
				Scope(state: /MainState.chooseAccounts, action: /MainAction.chooseAccounts) {
					ChooseAccounts()
				}
				Scope(state: /MainState.signAndSubmitTransaction, action: /MainAction.signAndSubmitTransaction) {
					TransactionSigning()
				}
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
			.presentationDestination(\.$personaNotFoundErrorAlert, action: /Action.view .. ViewAction.personaNotFoundErrorAlert) {
				EmptyReducer()
			}
	}

	@Dependency(\.profileClient) var profileClient

	func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			// NB: this if let should become a one liner with native case paths:
			// if let usePersonaRequest = state.remoteInteractions.items[keyPath: \.request?.authorized?.auth?.usePersona?] {
			if let usePersonaItem = { () -> P2P.FromDapp.WalletInteraction.AuthUsePersonaRequestItem? in
				switch state.remoteInteraction.items {
				case let .request(.authorized(item)):
					switch item.auth {
					case let .usePersona(item): return item
					default: return nil
					}
				default: return nil
				}
			}() {
				return .run { [usePersonaItem, dappDefinitionAddress = state.remoteInteraction.metadata.dAppDefinitionAddress] send in
					let identityAddress = try IdentityAddress(address: usePersonaItem.identityAddress)
					if let persona = try await profileClient.getPersonas().first(by: identityAddress) {
						let authorizedDapp = try await profileClient.getAuthorizedDapps().first(by: dappDefinitionAddress)
						let authorizedPersona = authorizedDapp?.referencesToAuthorizedPersonas.first(by: identityAddress)
						await send(.internal(.usePersona(usePersonaItem, persona, authorizedDapp, authorizedPersona)))
					} else {
						await send(.internal(.presentPersonaNotFoundErrorAlert(reason: "")))
					}
				} catch: { error, send in
					await send(.internal(.presentPersonaNotFoundErrorAlert(reason: error.legibleLocalizedDescription)))
				}
			} else {
				return .none
			}
		case let .personaNotFoundErrorAlert(.presented(action)):
			switch action {
			case .cancelButtonTapped:
				// FIXME: .rejectedByUser should perhaps be a different, more specialized error (.invalidSpecifiedPersona?)
				return dismissEffect(for: state, errorKind: .rejectedByUser, message: nil)
			}
		case .personaNotFoundErrorAlert:
			return .none
		case .closeButtonTapped:
			return dismissEffect(for: state, errorKind: .rejectedByUser, message: nil)
		case .backButtonTapped:
			return goBackEffect(for: &state)
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .usePersona(item, persona, authorizedDapp, authorizedPersona):
			state.persona = persona
			state.authorizedDapp = authorizedDapp
			state.authorizedPersona = authorizedPersona

			state.responseItems[.remote(.auth(.usePersona(item)))] = .remote(.auth(.usePersona(.init(
				persona: .init(
					identityAddress: persona.address.address,
					label: persona.displayName.rawValue
				)
			))))

			return autofillOngoingResponseItemsIfPossibleEffect(for: &state)

		case let .autofillOngoingResponseItemsIfPossible(payload):
			if let accountsPayload = payload.accountsPayload {
				state.responseItems[.local(.permissionRequested(.accounts(accountsPayload.numberOfAccountsRequested)))] = .local(.permissionGranted)
				setAccountsResponse(
					to: accountsPayload.requestItem,
					accountsPayload.accounts,
					accessKind: .ongoing,
					into: &state
				)
			}
			return continueEffect(for: &state)

		case let .presentPersonaNotFoundErrorAlert(reason):
			state.personaNotFoundErrorAlert = .init(
				title: { TextState(L10n.App.errorOccurredTitle) },
				actions: {
					ButtonState(role: .cancel, action: .send(.cancelButtonTapped)) {
						TextState(L10n.DApp.Request.SpecifiedPersonaNotFoundError.cancelButtonTitle)
					}
				},
				message: { TextState(L10n.DApp.Request.SpecifiedPersonaNotFoundError.message(reason)) }
			)
			return .none
		}
	}

	func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case
			let .root(.relay(item, .login(.delegate(.continueButtonTapped(persona, authorizedDapp, authorizedPersona))))),
			let .path(.element(_, .relay(item, .login(.delegate(.continueButtonTapped(persona, authorizedDapp, authorizedPersona)))))):
			state.persona = persona
			state.authorizedDapp = authorizedDapp
			state.authorizedPersona = authorizedPersona

			let responseItem: State.AnyInteractionResponseItem = .remote(.auth(.login(.withoutChallenge(.init(
				persona: .init(
					identityAddress: persona.address.address,
					label: persona.displayName.rawValue
				)
			)))))
			state.responseItems[item] = responseItem

			return autofillOngoingResponseItemsIfPossibleEffect(for: &state)
		case
			let .root(.relay(item, .permission(.delegate(.continueButtonTapped)))),
			let .path(.element(_, .relay(item, .permission(.delegate(.continueButtonTapped))))):

			let responseItem: State.AnyInteractionResponseItem = .local(.permissionGranted)
			state.responseItems[item] = responseItem
			return continueEffect(for: &state)
		case
			let .root(.relay(item, .chooseAccounts(.delegate(.continueButtonTapped(accounts, accessKind))))),
			let .path(.element(_, .relay(item, .chooseAccounts(.delegate(.continueButtonTapped(accounts, accessKind)))))):

			setAccountsResponse(to: item, accounts, accessKind: accessKind, into: &state)
			return continueEffect(for: &state)
		case
			let .root(.relay(item, .signAndSubmitTransaction(.delegate(.signedTXAndSubmittedToGateway(txID))))),
			let .path(.element(_, .relay(item, .signAndSubmitTransaction(.delegate(.signedTXAndSubmittedToGateway(txID)))))):

			state.responseItems[item] = .remote(.send(.init(txID: txID)))
			return continueEffect(for: &state)
		case
			let .root(.relay(_, .signAndSubmitTransaction(.delegate(.failed(error))))),
			let .path(.element(_, .relay(_, .signAndSubmitTransaction(.delegate(.failed(error)))))):

			let (errorKind, message) = error.errorKindAndMessage
			return dismissEffect(for: state, errorKind: errorKind, message: message)

		default:
			return .none
		}
	}

	func autofillOngoingResponseItemsIfPossibleEffect(
		for state: inout State
	) -> EffectTask<Action> {
		.run { [state] send in
			var payload = InternalAction.AutofillOngoingResponseItemsPayload()

			// TODO: autofill persona data here too

			if
				let ongoingAccountsRequestItem = { () -> P2P.FromDapp.WalletInteraction.OngoingAccountsRequestItem? in
					switch state.remoteInteraction.items {
					case let .request(.authorized(items)):
						return items.ongoingAccounts
					default:
						return nil
					}
				}(),
				let sharedAccounts = state.authorizedPersona?.sharedAccounts
			{
				if ongoingAccountsRequestItem.numberOfAccounts == sharedAccounts.request {
					let allAccounts = try await profileClient.getAccounts()
					if
						let selectedAccounts = try? sharedAccounts.accountsReferencedByAddress.compactMap({ sharedAccount in
							allAccounts.first(by: try .init(address: sharedAccount.address))
						}),
						selectedAccounts.count == sharedAccounts.accountsReferencedByAddress.count
					{
						payload.accountsPayload = .init(
							requestItem: .remote(.ongoingAccounts(ongoingAccountsRequestItem)),
							accounts: selectedAccounts,
							numberOfAccountsRequested: sharedAccounts.request
						)
					}
				}
			}

			await send(.internal(.autofillOngoingResponseItemsIfPossible(payload)))
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
			if let response = P2P.ToDapp.WalletInteractionSuccessResponse(
				for: state.remoteInteraction,
				with: state.responseItems.values.compactMap(/State.AnyInteractionResponseItem.remote)
			) {
				return .run { [state] send in
					// Save login date, data fields, and ongoing accounts to Profile
					if let persona = state.persona {
						let networkID = await profileClient.getCurrentNetworkID()
						var authorizedDapp = state.authorizedDapp ?? .init(
							networkID: networkID,
							dAppDefinitionAddress: state.remoteInteraction.metadata.dAppDefinitionAddress,
							displayName: state.dappMetadata.name
						)
						// This extraction is really verbose right now, but it should become a lot simpler with native case paths
						let sharedAccountsInfo = { () -> (P2P.FromDapp.WalletInteraction.NumberOfAccounts, [P2P.ToDapp.WalletAccount])? in
							let numberOfAccounts: P2P.FromDapp.WalletInteraction.NumberOfAccounts
							switch state.remoteInteraction.items {
							case let .request(.authorized(items)):
								if let ongoingAccounts = items.ongoingAccounts {
									numberOfAccounts = ongoingAccounts.numberOfAccounts
								} else {
									return nil
								}
							default:
								return nil
							}

							let accounts: [P2P.ToDapp.WalletAccount]
							switch response.items {
							case let .request(.authorized(items)):
								switch items.ongoingAccounts {
								case let .withProof(item):
									accounts = item.accounts.map(\.account)
								case let .withoutProof(item):
									accounts = item.accounts
								default:
									return nil
								}
							default:
								return nil
							}
							return (numberOfAccounts, accounts)
						}()
						let sharedAccounts: OnNetwork.AuthorizedDapp.AuthorizedPersonaSimple.SharedAccounts?
						if let (numberOfAccounts, accounts) = sharedAccountsInfo {
							sharedAccounts = try .init(
								accountsReferencedByAddress: OrderedSet(try accounts.map { try .init(address: $0.address) }),
								forRequest: numberOfAccounts
							)
						} else {
							sharedAccounts = nil
						}
						@Dependency(\.date) var now
						let authorizedPersona: OnNetwork.AuthorizedDapp.AuthorizedPersonaSimple = {
							if var authorizedPersona = state.authorizedPersona {
								// NB: update personal data fields here
								authorizedPersona.lastLogin = now()
								if let sharedAccounts = sharedAccounts {
									authorizedPersona.sharedAccounts = sharedAccounts
								}
								return authorizedPersona
							} else {
								return .init(
									identityAddress: persona.address,
									fieldIDs: [], // NB: set personal data fields here
									lastLogin: now(),
									sharedAccounts: sharedAccounts
								)
							}
						}()
						authorizedDapp.referencesToAuthorizedPersonas[id: authorizedPersona.id] = authorizedPersona
						// FIXME: @Cyon these add/update funcs should probably be one single function.
						// Something like `profileClient.saveAuthorizedDapp` which updates by
						// dApp ID or adds the whole dApp if it doesn't exist.
						if state.authorizedDapp == nil {
							try await profileClient.addAuthorizedDapp(authorizedDapp)
						} else {
							try await profileClient.updateAuthorizedDapp(authorizedDapp)
						}
					}

					await send(.delegate(.submit(response, state.dappMetadata)))
				}
			} else {
				return .none // TODO: throw error (invalid response format)
			}
		}
	}

	func goBackEffect(for state: inout State) -> EffectTask<Action> {
		state.responseItems.removeLast()
		state.path.removeLast()
		return .none
	}

	func dismissEffect(
		for state: State,
		errorKind: P2P.ToDapp.WalletInteractionFailureResponse.ErrorType,
		message: String?
	) -> EffectTask<Action> {
		.send(.delegate(.dismiss(.init(
			interactionId: state.remoteInteraction.id,
			errorType: errorKind,
			message: message
		))))
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
			self = .relayed(anyItem, with: .login(.init(
				dappDefinitionAddress: interaction.metadata.dAppDefinitionAddress,
				dappMetadata: dappMetadata
			)))
		case let .local(.permissionRequested(permissionKind)):
			self = .relayed(anyItem, with: .permission(.init(
				permissionKind: permissionKind,
				dappMetadata: dappMetadata
			)))
		case let .remote(.ongoingAccounts(item)):
			self = .relayed(anyItem, with: .chooseAccounts(.init(
				accessKind: .ongoing,
				dappDefinitionAddress: interaction.metadata.dAppDefinitionAddress,
				dappMetadata: dappMetadata,
				numberOfAccounts: item.numberOfAccounts
			)))
		case let .remote(.oneTimeAccounts(item)):
			self = .relayed(anyItem, with: .chooseAccounts(.init(
				accessKind: .oneTime,
				dappDefinitionAddress: interaction.metadata.dAppDefinitionAddress,
				dappMetadata: dappMetadata,
				numberOfAccounts: item.numberOfAccounts
			)))
		case let .remote(.send(item)):
			self = .relayed(anyItem, with: .signAndSubmitTransaction(.init(
				transactionManifestWithoutLockFee: item.transactionManifest
			)))
		}
	}
}
