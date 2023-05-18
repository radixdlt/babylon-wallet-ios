import AccountsClient
import AuthorizedDappsClient
import Cryptography
import FeaturePrelude
import GatewaysClient
import PersonasClient
import ROLAClient
import TransactionClient
import TransactionReviewFeature

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

		typealias RemoteInteraction = P2P.Dapp.Request
		typealias RemoteInteractionItem = P2P.Dapp.Request.AnyInteractionItem
		typealias RemoteInteractionResponseItem = P2P.Dapp.Response.WalletInteractionSuccessResponse.AnyInteractionResponseItem

		enum LocalInteractionItem: Sendable, Hashable {
			case accountPermissionRequested(DappInteraction.NumberOfAccounts)
		}

		enum LocalInteractionResponseItem: Sendable, Hashable {
			case accountPermissionGranted
		}

		let dappMetadata: DappMetadata
		let remoteInteraction: RemoteInteraction
		var persona: Profile.Network.Persona?
		var authorizedDapp: Profile.Network.AuthorizedDapp?
		var authorizedPersona: Profile.Network.AuthorizedDapp.AuthorizedPersonaSimple?

		let interactionItems: NonEmpty<OrderedSet<AnyInteractionItem>>
		var responseItems: OrderedDictionary<AnyInteractionItem, AnyInteractionResponseItem> = [:]

		@PresentationState
		var personaNotFoundErrorAlert: AlertState<ViewAction.PersonaNotFoundErrorAlertAction>? = nil

		var root: Destinations.State?
		var path: StackState<Destinations.State> = []

		init?(
			dappMetadata: DappMetadata,
			interaction remoteInteraction: RemoteInteraction
		) {
			self.dappMetadata = dappMetadata
			self.remoteInteraction = remoteInteraction

			if let interactionItems = NonEmpty(rawValue: OrderedSet<AnyInteractionItem>(for: remoteInteraction.erasedItems)) {
				self.interactionItems = interactionItems
				self.root = Destinations.State(
					for: interactionItems.first,
					interaction: remoteInteraction,
					dappMetadata: dappMetadata,
					persona: nil
				)
			} else {
				return nil
			}
		}
	}

	enum ViewAction: Sendable, Equatable {
		case appeared
		case closeButtonTapped
		case backButtonTapped
		case personaNotFoundErrorAlert(PresentationAction<PersonaNotFoundErrorAlertAction>)

		enum PersonaNotFoundErrorAlertAction: Sendable, Equatable {
			case cancelButtonTapped
		}
	}

	enum InternalAction: Sendable, Equatable {
		case usePersona(
			P2P.Dapp.Request.AuthUsePersonaRequestItem,
			Profile.Network.Persona,
			Profile.Network.AuthorizedDapp,
			Profile.Network.AuthorizedDapp.AuthorizedPersonaSimple
		)
		case presentPersonaNotFoundErrorAlert(reason: String)
		case autofillOngoingResponseItemsIfPossible(AutofillOngoingResponseItemsPayload)

		struct AutofillOngoingResponseItemsPayload: Sendable, Equatable {
			struct AccountsPayload: Sendable, Equatable {
				var requestItem: DappInteractionFlow.State.AnyInteractionItem
				var numberOfAccountsRequested: DappInteraction.NumberOfAccounts
				var accounts: [Profile.Network.Account]
			}

			struct PersonaDataPayload: Sendable, Equatable {
				var requestItem: DappInteractionFlow.State.AnyInteractionItem
				var fieldsRequested: Set<Profile.Network.Persona.Field.ID>
				var fields: IdentifiedArrayOf<Profile.Network.Persona.Field>
			}

			var ongoingAccountsPayload: AccountsPayload?
			var ongoingPersonaDataPayload: PersonaDataPayload?
		}
	}

	enum ChildAction: Sendable, Equatable {
		case root(Destinations.Action)
		case path(StackAction<Destinations.Action>)
	}

	enum DelegateAction: Sendable, Equatable {
		case dismissWithFailure(P2P.Dapp.Response.WalletInteractionFailureResponse)
		case dismissWithSuccess(DappMetadata)
		case submit(P2P.Dapp.Response.WalletInteractionSuccessResponse, DappMetadata)
	}

	struct Destinations: Sendable, ReducerProtocol {
		typealias State = RelayState<DappInteractionFlow.State.AnyInteractionItem, MainState>
		typealias Action = RelayAction<DappInteractionFlow.State.AnyInteractionItem, MainAction>

		enum MainState: Sendable, Hashable {
			case login(Login.State)
			case accountPermission(AccountPermission.State)
			case chooseAccounts(ChooseAccounts.State)
			case personaDataPermission(PersonaDataPermission.State)
			case oneTimePersonaData(OneTimePersonaData.State)
			case reviewTransaction(TransactionReview.State)
		}

		enum MainAction: Sendable, Equatable {
			case login(Login.Action)
			case accountPermission(AccountPermission.Action)
			case chooseAccounts(ChooseAccounts.Action)
			case personaDataPermission(PersonaDataPermission.Action)
			case oneTimePersonaData(OneTimePersonaData.Action)
			case reviewTransaction(TransactionReview.Action)
		}

		var body: some ReducerProtocolOf<Self> {
			Relay {
				EmptyReducer()
					.ifCaseLet(/MainState.login, action: /MainAction.login) {
						Login()
					}
					.ifCaseLet(/MainState.accountPermission, action: /MainAction.accountPermission) {
						AccountPermission()
					}
					.ifCaseLet(/MainState.chooseAccounts, action: /MainAction.chooseAccounts) {
						ChooseAccounts()
					}
					.ifCaseLet(/MainState.personaDataPermission, action: /MainAction.personaDataPermission) {
						PersonaDataPermission()
					}
					.ifCaseLet(/MainState.oneTimePersonaData, action: /MainAction.oneTimePersonaData) {
						OneTimePersonaData()
					}
					.ifCaseLet(/MainState.reviewTransaction, action: /MainAction.reviewTransaction) {
						TransactionReview()
					}
			}
		}
	}

	var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.ifLet(\.root, action: /Action.child .. ChildAction.root) {
				Destinations()
			}
			.forEach(\.path, action: /Action.child .. ChildAction.path) {
				Destinations()
			}
			.ifLet(\.$personaNotFoundErrorAlert, action: /Action.view .. ViewAction.personaNotFoundErrorAlert)
	}

	@Dependency(\.gatewaysClient) var gatewaysClient
	@Dependency(\.personasClient) var personasClient
	@Dependency(\.accountsClient) var accountsClient
	@Dependency(\.authorizedDappsClient) var authorizedDappsClient

	func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			guard let usePersonaRequestItem = state.usePersonaRequestItem else {
				return .none
			}

			return .run { [dappDefinitionAddress = state.dappMetadata.dAppDefinitionAddress] send in

				let identityAddress = usePersonaRequestItem.identityAddress
				guard
					let persona = try await personasClient.getPersonas()[id: identityAddress],
					let authorizedDapp = try await authorizedDappsClient.getAuthorizedDapps()[id: dappDefinitionAddress],
					let authorizedPersona = authorizedDapp.referencesToAuthorizedPersonas[id: identityAddress]
				else {
					await send(.internal(.presentPersonaNotFoundErrorAlert(reason: "")))
					return
				}

				await send(.internal(.usePersona(usePersonaRequestItem, persona, authorizedDapp, authorizedPersona)))

			} catch: { error, send in
				await send(.internal(.presentPersonaNotFoundErrorAlert(reason: error.legibleLocalizedDescription)))
			}

		case let .personaNotFoundErrorAlert(.presented(action)):
			switch action {
			case .cancelButtonTapped:
				return dismissEffect(for: state, errorKind: .invalidPersona, message: nil)
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
					identityAddress: persona.address,
					label: persona.displayName
				)
			))))

			resetOngoingResponseItemsIfNeeded(for: &state)

			return autofillOngoingResponseItemsIfPossibleEffect(for: state)

		case let .autofillOngoingResponseItemsIfPossible(payload):
			if let ongoingAccountsWithoutProofOfOwnership = payload.ongoingAccountsPayload {
				state.responseItems[.local(.accountPermissionRequested(ongoingAccountsWithoutProofOfOwnership.numberOfAccountsRequested))] = .local(.accountPermissionGranted)
				setAccountsResponse(
					to: ongoingAccountsWithoutProofOfOwnership.requestItem,
					accessKind: .ongoing,
					chosenAccounts: .withoutProofOfOwnership(.init(uniqueElements: ongoingAccountsWithoutProofOfOwnership.accounts)),
					into: &state
				)
			}
			if let ongoingPersonaDataPayload = payload.ongoingPersonaDataPayload {
				let fields = ongoingPersonaDataPayload.fields.map { P2P.Dapp.Response.PersonaData(field: $0.id, value: $0.value) }
				state.responseItems[.remote(.ongoingPersonaData(.init(fields: ongoingPersonaDataPayload.fieldsRequested)))] = .remote(.ongoingPersonaData(.init(fields: fields)))
			}
			return continueEffect(for: &state)

		case let .presentPersonaNotFoundErrorAlert(reason):
			state.personaNotFoundErrorAlert = .init(
				title: { TextState(L10n.Common.errorAlertTitle) },
				actions: {
					ButtonState(role: .cancel, action: .send(.cancelButtonTapped)) {
						TextState(L10n.Common.cancel)
					}
				},
				message: {
					#if DEBUG
					TextState(L10n.DAppRequest.RequestPersonaNotFoundAlert.message + "\n\n" + reason)
					#else
					TextState(L10n.DAppRequest.RequestPersonaNotFoundAlert.message)
					#endif
				}
			)
			return .none
		}
	}

	func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		func handleLogin(
			_ item: State.AnyInteractionItem,
			_ persona: Profile.Network.Persona,
			_ authorizedDapp: Profile.Network.AuthorizedDapp?,
			_ authorizedPersona: Profile.Network.AuthorizedDapp.AuthorizedPersonaSimple?,
			_ signedAuthChallenge: SignedAuthChallenge?
		) -> EffectTask<Action> {
			state.persona = persona
			state.authorizedDapp = authorizedDapp
			state.authorizedPersona = authorizedPersona

			let responsePersona = P2P.Dapp.Response.Persona(
				identityAddress: persona.address,
				label: persona.displayName
			)

			if let signedAuthChallenge {
				guard
					// A **single** signature expected, since we sign auth with a single Persona.
					let entitySignature = signedAuthChallenge.entitySignatures.first,
					signedAuthChallenge.entitySignatures.count == 1
				else {
					return dismissEffect(for: state, errorKind: .failedToSignAuthChallenge, message: "Failed to serialize signature")
				}
				let proof = P2P.Dapp.Response.AuthProof(entitySignature: entitySignature)

				state.responseItems[item] = .remote(.auth(.login(.withChallenge(.init(
					persona: responsePersona,
					challenge: signedAuthChallenge.challenge,
					proof: proof
				)))))

			} else {
				state.responseItems[item] = .remote(.auth(.login(.withoutChallenge(.init(
					persona: responsePersona
				)))))
			}

			resetOngoingResponseItemsIfNeeded(for: &state)

			return autofillOngoingResponseItemsIfPossibleEffect(for: state)
		}

		func handleAccountPermission(_ item: State.AnyInteractionItem) -> EffectTask<Action> {
			let responseItem: State.AnyInteractionResponseItem = .local(.accountPermissionGranted)
			state.responseItems[item] = responseItem
			return continueEffect(for: &state)
		}

		func handleAccounts(
			_ item: State.AnyInteractionItem,
			_ choseAccounts: ChooseAccountsResult,
			_ accessKind: ChooseAccounts.State.AccessKind
		) -> EffectTask<Action> {
			setAccountsResponse(
				to: item,
				accessKind: accessKind,
				chosenAccounts: choseAccounts,
				into: &state
			)
			return continueEffect(for: &state)
		}

		func handlePersonaUpdated(
			_ state: inout State,
			_ persona: Profile.Network.Persona
		) -> EffectTask<Action> {
			guard state.persona?.id == persona.id else {
				return .none
			}
			state.persona = persona
			let responsePersona = P2P.Dapp.Response.Persona(persona: persona)
			for (request, response) in state.responseItems {
				// NB: native case paths should simplify this mutation logic a lot
				switch response {
				case let .remote(.auth(.login(.withChallenge(item)))):
					state.responseItems[request] = .remote(.auth(.login(.withChallenge(.init(
						persona: responsePersona,
						challenge: item.challenge,
						proof: item.proof
					)))))
				case .remote(.auth(.login(.withoutChallenge))):
					state.responseItems[request] = .remote(.auth(.login(.withoutChallenge(.init(
						persona: responsePersona
					)))))
				case .remote(.auth(.usePersona)):
					state.responseItems[request] = .remote(.auth(.usePersona(.init(
						persona: responsePersona
					))))
				default:
					continue
				}
			}
			return .none
		}

		func handleOngoingPersonaDataPermission(
			_ item: State.AnyInteractionItem,
			_ fields: IdentifiedArrayOf<Profile.Network.Persona.Field>
		) -> EffectTask<Action> {
			let fields = fields.map { P2P.Dapp.Response.PersonaData(field: $0.id, value: $0.value) }
			state.responseItems[item] = .remote(.ongoingPersonaData(.init(fields: fields)))
			return continueEffect(for: &state)
		}

		func handleOneTimePersonaData(
			_ item: State.AnyInteractionItem,
			_ fields: IdentifiedArrayOf<Profile.Network.Persona.Field>
		) -> EffectTask<Action> {
			let fields = fields.map { P2P.Dapp.Response.PersonaData(field: $0.id, value: $0.value) }
			state.responseItems[item] = .remote(.oneTimePersonaData(.init(fields: fields)))
			return continueEffect(for: &state)
		}

		func handleSignAndSubmitTX(
			_ item: State.AnyInteractionItem,
			_ txID: TransactionIntent.TXID
		) -> EffectTask<Action> {
			state.responseItems[item] = .remote(.send(.init(txID: txID)))
			return continueEffect(for: &state)
		}

		func handleSignAndSubmitTXFailed(
			_ error: TransactionFailure
		) -> EffectTask<Action> {
			let (errorKind, message) = error.errorKindAndMessage
			return dismissEffect(for: state, errorKind: errorKind, message: message)
		}

		guard let (item, action) = childAction.itemAndAction else { return .none }
		switch action {
		case .login(.delegate(.failedToSignAuthChallenge)):
			return dismissEffect(
				for: state,
				errorKind: .failedToSignAuthChallenge,
				message: nil
			)

		case let .login(.delegate(.continueButtonTapped(persona, authorizedDapp, authorizedPersona, signedAuthChallenge))):
			return handleLogin(item, persona, authorizedDapp, authorizedPersona, signedAuthChallenge)

		case .accountPermission(.delegate(.continueButtonTapped)):
			return handleAccountPermission(item)

		case let .chooseAccounts(.delegate(.continueButtonTapped(accessKind, chosenAccounts))):
			return handleAccounts(item, chosenAccounts, accessKind)

		case let .personaDataPermission(.delegate(.personaUpdated(persona))):
			return handlePersonaUpdated(&state, persona)

		case let .personaDataPermission(.delegate(.continueButtonTapped(fields))):
			return handleOngoingPersonaDataPermission(item, fields)

		case let .oneTimePersonaData(.delegate(.personaUpdated(persona))):
			return handlePersonaUpdated(&state, persona)

		case let .oneTimePersonaData(.delegate(.continueButtonTapped(fields))):
			return handleOneTimePersonaData(item, fields)

		case let .reviewTransaction(.delegate(.signedTXAndSubmittedToGateway(txID))):
			return handleSignAndSubmitTX(item, txID)

		case .reviewTransaction(.delegate(.transactionCompleted)):
			return .send(.delegate(.dismissWithSuccess(state.dappMetadata)))

		case let .reviewTransaction(.delegate(.failed(error))):
			return handleSignAndSubmitTXFailed(error)

		default:
			return .none
		}
	}

	func resetOngoingResponseItemsIfNeeded(
		for state: inout State
	) {
		guard
			let resetItem = state.resetRequestItem,
			var authorizedDapp = state.authorizedDapp,
			var authorizedPersona = state.authorizedPersona
		else {
			return
		}
		if resetItem.accounts {
			authorizedPersona.sharedAccounts = nil
		}
		if resetItem.personaData {
			authorizedPersona.sharedFieldIDs = nil
		}
		authorizedDapp.referencesToAuthorizedPersonas[id: authorizedPersona.id] = authorizedPersona
		state.authorizedDapp = authorizedDapp
		state.authorizedPersona = authorizedPersona
	}

	func autofillOngoingResponseItemsIfPossibleEffect(
		for state: State
	) -> EffectTask<Action> {
		.run { [state] send in
			var payload = InternalAction.AutofillOngoingResponseItemsPayload()

			payload.ongoingAccountsPayload = try await { () async throws -> InternalAction.AutofillOngoingResponseItemsPayload.AccountsPayload? in
				guard
					let ongoingAccountsRequestItem = state.ongoingAccountsRequestItem,
					ongoingAccountsRequestItem.challenge == nil, // autofill not supported for accounts with proof of ownership
					let sharedAccounts = state.authorizedPersona?.sharedAccounts,
					ongoingAccountsRequestItem.numberOfAccounts == sharedAccounts.request
				else {
					return nil
				}
				let allAccounts = try await accountsClient.getAccountsOnCurrentNetwork()

				guard
					let selectedAccounts = try? sharedAccounts.accountsReferencedByAddress.compactMap({ sharedAccount in
						try allAccounts[id: .init(address: sharedAccount.address)]
					}),
					selectedAccounts.count == sharedAccounts.accountsReferencedByAddress.count
				else { return nil }

				return .init(
					requestItem: .remote(.ongoingAccounts(ongoingAccountsRequestItem)),
					numberOfAccountsRequested: sharedAccounts.request,
					accounts: selectedAccounts
				)
			}()

			payload.ongoingPersonaDataPayload = try await { () async throws -> InternalAction.AutofillOngoingResponseItemsPayload.PersonaDataPayload? in
				guard
					let ongoingPersonaDataRequestItem = state.ongoingPersonaDataRequestItem,
					let authorizedPersonaID = state.authorizedPersona?.id,
					let sharedFieldIDs = state.authorizedPersona?.sharedFieldIDs,
					ongoingPersonaDataRequestItem.fields.isSubset(of: sharedFieldIDs)
				else { return nil }

				let allPersonas = try await personasClient.getPersonas()
				guard let persona = allPersonas[id: authorizedPersonaID] else { return nil }
				let sharedFields = persona.fields.filter { sharedFieldIDs.contains($0.id) }
				guard sharedFields.count == sharedFieldIDs.count else { return nil }
				return .init(
					requestItem: .remote(.ongoingPersonaData(ongoingPersonaDataRequestItem)),
					fieldsRequested: sharedFieldIDs,
					fields: sharedFields
				)
			}()

			await send(.internal(.autofillOngoingResponseItemsIfPossible(payload)))
		} catch: { error, _ in
			loggerGlobal.warning("Unable to autofil ongoing response, error: \(error)")
		}
	}

	func setAccountsResponse(
		to item: State.AnyInteractionItem,
		accessKind: ChooseAccounts.State.AccessKind,
		chosenAccounts: P2P.Dapp.Response.Accounts,
		into state: inout State
	) {
		switch accessKind {
		case .oneTime:
			state.responseItems[item] = .remote(.oneTimeAccounts(.init(accounts: chosenAccounts)))
		case .ongoing:
			state.responseItems[item] = .remote(.ongoingAccounts(.init(accounts: chosenAccounts)))
		}
	}

	func continueEffect(for state: inout State) -> EffectTask<Action> {
		if
			let nextRequest = state.interactionItems.first(where: { state.responseItems[$0] == nil }),
			let destination = Destinations.State(
				for: nextRequest,
				interaction: state.remoteInteraction,
				dappMetadata: state.dappMetadata,
				persona: state.persona
			)
		{
			if state.root == nil {
				state.root = destination
			} else if state.path.last != destination {
				state.path.append(destination)
			}
			return .none
		} else {
			return finishInteractionFlow(state)
		}
	}

	func finishInteractionFlow(_ state: State) -> EffectTask<Action> {
		guard let response = P2P.Dapp.Response.WalletInteractionSuccessResponse(
			for: state.remoteInteraction,
			with: state.responseItems.values.compactMap(/State.AnyInteractionResponseItem.remote)
		) else {
			return .none // TODO: throw error (invalid response format)
		}

		return .run { [state] send in
			// Save login date, data fields, and ongoing accounts to Profile
			if let persona = state.persona {
				// FIXME: handle error
				try await updatePersona(persona, state, responseItems: response.items)
			}

			await send(.delegate(.submit(response, state.dappMetadata)))
		}
	}

	func updatePersona(
		_ persona: Profile.Network.Persona,
		_ state: State,
		responseItems: P2P.Dapp.Response.WalletInteractionSuccessResponse.Items
	) async throws {
		let networkID = await gatewaysClient.getCurrentNetworkID()
		var authorizedDapp = state.authorizedDapp ?? .init(
			networkID: networkID,
			dAppDefinitionAddress: state.dappMetadata.dAppDefinitionAddress,
			displayName: {
				switch state.dappMetadata {
				case let .ledger(ledger): return ledger.name
				case .request: return nil
				}
			}()
		)
		// This extraction is really verbose right now, but it should become a lot simpler with native case paths
		let sharedAccountsInfo: (P2P.Dapp.Request.NumberOfAccounts, [P2P.Dapp.Response.WalletAccount])? = unwrap(
			{
				switch state.remoteInteraction.items {
				case let .request(.authorized(items)):
					return items.ongoingAccounts?.numberOfAccounts
				default:
					return nil
				}
			}(),
			{
				switch responseItems {
				case let .request(.authorized(items)):
					return items.ongoingAccounts?.accounts
				default:
					return nil
				}
			}()
		)
		let sharedAccounts: Profile.Network.AuthorizedDapp.AuthorizedPersonaSimple.SharedAccounts?
		if let (numberOfAccounts, accounts) = sharedAccountsInfo {
			sharedAccounts = try .init(
				accountsReferencedByAddress: OrderedSet(accounts.map(\.address)),
				forRequest: numberOfAccounts
			)
		} else {
			sharedAccounts = nil
		}
		let sharedFieldIDs: Set<Profile.Network.Persona.Field.ID>? = {
			switch state.remoteInteraction.items {
			case let .request(.authorized(items)):
				return items.ongoingPersonaData?.fields
			default:
				return nil
			}
		}()
		@Dependency(\.date) var now
		let authorizedPersona: Profile.Network.AuthorizedDapp.AuthorizedPersonaSimple = {
			if var authorizedPersona = state.authorizedPersona {
				authorizedPersona.lastLogin = now()
				if let sharedAccounts {
					authorizedPersona.sharedAccounts = sharedAccounts
				}
				if let sharedFieldIDs {
					if let existingSharedFieldIDs = authorizedPersona.sharedFieldIDs {
						authorizedPersona.sharedFieldIDs = existingSharedFieldIDs.union(sharedFieldIDs)
					} else {
						authorizedPersona.sharedFieldIDs = sharedFieldIDs
					}
				}
				return authorizedPersona
			} else {
				return .init(
					identityAddress: persona.address,
					lastLogin: now(),
					sharedAccounts: sharedAccounts,
					sharedFieldIDs: sharedFieldIDs
				)
			}
		}()
		authorizedDapp.referencesToAuthorizedPersonas[id: authorizedPersona.id] = authorizedPersona
		try await authorizedDappsClient.updateOrAddAuthorizedDapp(authorizedDapp)
	}

	func goBackEffect(for state: inout State) -> EffectTask<Action> {
		state.responseItems.removeLast()
		state.path.removeLast()
		return .none
	}

	func dismissEffect(
		for state: State,
		errorKind: P2P.Dapp.Response.WalletInteractionFailureResponse.ErrorType,
		message: String?
	) -> EffectTask<Action> {
		.send(.delegate(.dismissWithFailure(.init(
			interactionId: state.remoteInteraction.id,
			errorType: errorKind,
			message: message
		))))
	}
}

extension OrderedSet<DappInteractionFlow.State.AnyInteractionItem> {
	init(
		for remoteInteractionItems: some Collection<DappInteractionFlow.State.RemoteInteractionItem>
	) {
		self.init(
			remoteInteractionItems
				.sorted(by: { $0.priority < $1.priority })
				.reduce(into: []) { items, currentItem in
					switch currentItem {
					case let .ongoingAccounts(item):
						items.append(.local(.accountPermissionRequested(item.numberOfAccounts)))
						fallthrough
					default:
						items.append(.remote(currentItem))
					}
				}
		)
	}
}

extension DappInteractionFlow.ChildAction {
	var itemAndAction: (DappInteractionFlow.State.AnyInteractionItem, DappInteractionFlow.Destinations.MainAction)? {
		switch self {
		case let .root(.relay(item, action)), let .path(.element(_, .relay(item, action))):
			return (item, action)

		case .path(.popFrom):
			return nil
		}
	}
}

extension DappInteractionFlow.Destinations.State {
	init?(
		for anyItem: DappInteractionFlow.State.AnyInteractionItem,
		interaction: DappInteractionFlow.State.RemoteInteraction,
		dappMetadata: DappMetadata,
		persona: Profile.Network.Persona?
	) {
		switch anyItem {
		case .remote(.auth(.usePersona)):
			return nil
		case let .remote(.auth(.login(loginRequest))):
			self = .relayed(anyItem, with: .login(.init(
				dappMetadata: dappMetadata,
				loginRequest: loginRequest
			)))

		case let .local(.accountPermissionRequested(numberOfAccounts)):
			self = .relayed(anyItem, with: .accountPermission(.init(
				dappMetadata: dappMetadata,
				numberOfAccounts: numberOfAccounts
			)))

		case let .remote(.ongoingAccounts(item)):
			self = .relayed(anyItem, with: .chooseAccounts(.init(
				challenge: item.challenge,
				accessKind: .ongoing,
				dappMetadata: dappMetadata,
				numberOfAccounts: item.numberOfAccounts,
				_chooseAccounts: .init(selectionRequirement: .exactly(1))
			)))

		case let .remote(.oneTimeAccounts(item)):
			self = .relayed(anyItem, with: .chooseAccounts(.init(
				challenge: item.challenge,
				accessKind: .oneTime,
				dappMetadata: dappMetadata,
				numberOfAccounts: item.numberOfAccounts,
				_chooseAccounts: .init(selectionRequirement: .exactly(1))
			)))

		case let .remote(.oneTimePersonaData(item)):
			self = .relayed(anyItem, with: .oneTimePersonaData(.init(
				dappMetadata: dappMetadata,
				requiredFieldIDs: item.fields
			)))

		case let .remote(.ongoingPersonaData(item)):
			if let persona {
				self = .relayed(anyItem, with: .personaDataPermission(.init(
					dappMetadata: dappMetadata,
					personaID: persona.id,
					requiredFieldIDs: item.fields
				)))
			} else {
				assertionFailure("Persona data request requires a persona.")
				return nil
			}

		case let .remote(.send(item)):
			self = .relayed(anyItem, with: .reviewTransaction(.init(
				transactionManifest: item.transactionManifest,
				signTransactionPurpose: .manifestFromDapp,
				message: item.message
			)))
		}
	}
}

extension DappInteractionFlow.State {
	var usePersonaRequestItem: P2P.Dapp.Request.AuthUsePersonaRequestItem? {
		// NB: this should become a one liner with native case paths:
		// remoteInteractions.items[keyPath: \.request?.authorized?.auth?.usePersona?]
		guard
			case let .request(.authorized(item)) = remoteInteraction.items,
			case let .usePersona(item) = item.auth
		else {
			return nil
		}
		return item
	}

	var resetRequestItem: P2P.Dapp.Request.ResetRequestItem? {
		// NB: this should become a one liner with native case paths:
		// remoteInteractions.items[keyPath: \.request?.authorized?.reset]
		guard
			case let .request(.authorized(item)) = remoteInteraction.items
		else {
			return nil
		}
		return item.reset
	}

	var ongoingAccountsRequestItem: P2P.Dapp.Request.AccountsRequestItem? {
		// NB: this should become a one liner with native case paths:
		// remoteInteractions.items[keyPath: \.request?.authorized?.ongoingAccounts]
		guard
			case let .request(.authorized(item)) = remoteInteraction.items
		else {
			return nil
		}
		return item.ongoingAccounts
	}

	var oneTimeAccountsRequestItem: P2P.Dapp.Request.AccountsRequestItem? {
		// NB: this should become a one liner with native case paths:
		// remoteInteractions.items[keyPath: \.request?.authorized?.oneTimeAccountsRequestItem]
		guard
			case let .request(.authorized(item)) = remoteInteraction.items
		else {
			return nil
		}
		return item.oneTimeAccounts
	}

	var oneTimePersonaDataRequestItem: P2P.Dapp.Request.PersonaDataRequestItem? {
		// NB: this should become a one liner with native case paths:
		// remoteInteractions.items[keyPath: \.request?.authorized?.oneTimePersonaDataRequestItem]
		guard
			case let .request(.authorized(item)) = remoteInteraction.items
		else {
			return nil
		}
		return item.oneTimePersonaData
	}

	var ongoingPersonaDataRequestItem: P2P.Dapp.Request.PersonaDataRequestItem? {
		// NB: this should become a one liner with native case paths:
		// remoteInteractions.items[keyPath: \.request?.authorized?.ongoingPersonaData]
		guard
			case let .request(.authorized(item)) = remoteInteraction.items
		else {
			return nil
		}
		return item.ongoingPersonaData
	}
}
