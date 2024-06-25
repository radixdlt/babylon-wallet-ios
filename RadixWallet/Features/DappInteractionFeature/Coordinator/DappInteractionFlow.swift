import Sargon

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

		typealias RemoteInteraction = DappToWalletInteraction
		typealias RemoteInteractionItem = DappToWalletInteraction.AnyInteractionItem
		typealias RemoteInteractionResponseItem = WalletToDappInteractionSuccessResponse.AnyInteractionResponseItem

		enum LocalInteractionItem: Sendable, Hashable {
			case accountPermissionRequested(DappInteractionNumberOfAccounts)
		}

		enum LocalInteractionResponseItem: Sendable, Hashable {
			case accountPermissionGranted
		}

		let dappMetadata: DappMetadata
		let remoteInteraction: RemoteInteraction
		var persona: Persona?
		var authorizedDapp: AuthorizedDapp?
		var authorizedPersona: AuthorizedPersonaSimple?

		let interactionItems: NonEmpty<OrderedSet<AnyInteractionItem>>
		var responseItems: OrderedDictionary<AnyInteractionItem, AnyInteractionResponseItem> = [:]

		@PresentationState
		var personaNotFoundErrorAlert: AlertState<ViewAction.PersonaNotFoundErrorAlertAction>? = nil

		var root: Path.State?
		var path: StackState<Path.State> = .init()

		var currentItem: AnyInteractionItem {
			if let last = path.last {
				return last.item
			} else if let root {
				return root.item
			} else {
				assertionFailure("Should be impossible")
				return interactionItems.first
			}
		}

		init?(
			dappMetadata: DappMetadata,
			interaction remoteInteraction: RemoteInteraction
		) {
			self.dappMetadata = dappMetadata
			self.remoteInteraction = remoteInteraction

			if let interactionItems = NonEmpty(rawValue: OrderedSet<AnyInteractionItem>(for: remoteInteraction.erasedItems)) {
				self.interactionItems = interactionItems
				self.root = Path.State(
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
			DappToWalletInteractionAuthUsePersonaRequestItem,
			Persona,
			AuthorizedDapp,
			AuthorizedPersonaSimple
		)
		case presentPersonaNotFoundErrorAlert(reason: String)
		case autofillOngoingResponseItemsIfPossible(AutofillOngoingResponseItemsPayload)
		case delayedAppendToPath(DappInteractionFlow.Path.State)

		struct AutofillOngoingResponseItemsPayload: Sendable, Equatable {
			struct AccountsPayload: Sendable, Equatable {
				var requestItem: DappInteractionFlow.State.AnyInteractionItem
				var numberOfAccountsRequested: DappInteractionNumberOfAccounts
				var accounts: [Account]
			}

			var ongoingAccountsPayload: AccountsPayload?

			var ongoingPersonaDataPayload: PersonaDataPayload?
		}

		case failedToUpdatePersonaAtEndOfFlow(
			persona: Persona,
			response: WalletToDappInteractionSuccessResponse,
			metadata: DappMetadata
		)
	}

	enum ChildAction: Sendable, Equatable {
		case root(Path.Action)
		case path(StackActionOf<Path>)
	}

	enum DelegateAction: Sendable, Equatable {
		case dismissWithFailure(WalletToDappInteractionFailureResponse)
		case dismissWithSuccess(DappMetadata, IntentHash)
		case submit(WalletToDappInteractionSuccessResponse, DappMetadata)
		case dismiss
	}

	struct Path: Sendable, Reducer {
		struct State: Sendable, Hashable {
			let item: DappInteractionFlow.State.AnyInteractionItem
			var state: MainState
		}

		@CasePathable
		enum MainState: Sendable, Hashable {
			case login(Login.State)
			case accountPermission(AccountPermission.State)
			case chooseAccounts(AccountPermissionChooseAccounts.State)
			case personaDataPermission(PersonaDataPermission.State)
			case oneTimePersonaData(OneTimePersonaData.State)
			case reviewTransaction(TransactionReview.State)
		}

		@CasePathable
		enum Action: Sendable, Equatable {
			case login(Login.Action)
			case accountPermission(AccountPermission.Action)
			case chooseAccounts(AccountPermissionChooseAccounts.Action)
			case personaDataPermission(PersonaDataPermission.Action)
			case oneTimePersonaData(OneTimePersonaData.Action)
			case reviewTransaction(TransactionReview.Action)
		}

		var body: some ReducerOf<Self> {
			Scope(state: \.state, action: \.self) {
				Scope(state: \.login, action: \.login) {
					Login()
				}
				Scope(state: \.accountPermission, action: \.accountPermission) {
					AccountPermission()
				}
				Scope(state: \.chooseAccounts, action: \.chooseAccounts) {
					AccountPermissionChooseAccounts()
				}
				Scope(state: \.personaDataPermission, action: \.personaDataPermission) {
					PersonaDataPermission()
				}
				Scope(state: \.oneTimePersonaData, action: \.oneTimePersonaData) {
					OneTimePersonaData()
				}
				Scope(state: \.reviewTransaction, action: \.reviewTransaction) {
					TransactionReview()
				}
			}
		}
	}

	var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(\.root, action: /Action.child .. ChildAction.root) {
				Path()
			}
			.forEach(\.path, action: /Action.child .. ChildAction.path) {
				Path()
			}
			.ifLet(\.$personaNotFoundErrorAlert, action: /Action.view .. ViewAction.personaNotFoundErrorAlert)
	}

	@Dependency(\.gatewaysClient) var gatewaysClient
	@Dependency(\.personasClient) var personasClient
	@Dependency(\.accountsClient) var accountsClient
	@Dependency(\.authorizedDappsClient) var authorizedDappsClient
	@Dependency(\.continuousClock) var clock

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
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
					let authorizedPersona = authorizedDapp.referencesToAuthorizedPersonas.first(where: { $0.identityAddress == identityAddress })
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

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .failedToUpdatePersonaAtEndOfFlow(_, response, dappMetadata):
			// FIXME: Figure out if we wanna do something differently... we FAILED to save the persona
			// into profile... yet still we are responding back to dapp with it.
			return .send(.delegate(.submit(response, dappMetadata)))

		case let .usePersona(item, persona, authorizedDapp, authorizedPersona):
			state.persona = persona
			state.authorizedDapp = authorizedDapp
			state.authorizedPersona = authorizedPersona

			state.responseItems[.remote(.auth(.usePersona(item)))] = .remote(.auth(.usePersona(.init(
				persona: .init(
					identityAddress: persona.address,
					label: persona.displayName.rawValue
				)
			))))

			resetOngoingResponseItemsIfNeeded(for: &state)

			return autofillOngoingResponseItemsIfPossibleEffect(for: state)

		case let .autofillOngoingResponseItemsIfPossible(payload):
			if let ongoingAccountsWithoutProofOfOwnership = payload.ongoingAccountsPayload {
				let numberOfAccountsRequested = ongoingAccountsWithoutProofOfOwnership.numberOfAccountsRequested
				let local = DappInteractionFlow.State.LocalInteractionItem.accountPermissionRequested(numberOfAccountsRequested)

				// Update state for `local` responseItems
				state.responseItems[.local(local)] = .local(.accountPermissionGranted)

				// Update state for `remote` responseItems
				setAccountsResponse(
					to: ongoingAccountsWithoutProofOfOwnership.requestItem,
					accessKind: .ongoing,
					chosenAccounts: .withoutProofOfOwnership(ongoingAccountsWithoutProofOfOwnership.accounts.asIdentified()),
					into: &state
				)
			}

			if let ongoingPersonaData = payload.ongoingPersonaDataPayload {
				state.responseItems[.remote(.ongoingPersonaData(ongoingPersonaData.personaDataRequested))] = .remote(.ongoingPersonaData(ongoingPersonaData.responseItem))
			}
			return continueEffect(for: &state)

		case let .delayedAppendToPath(destination):
			state.path.append(destination)
			return .none

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
}

extension DappInteractionFlow {
	func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		func handleLogin(
			_ item: State.AnyInteractionItem,
			_ persona: Persona,
			_ authorizedDapp: AuthorizedDapp?,
			_ authorizedPersona: AuthorizedPersonaSimple?,
			_ signedAuthChallenge: SignedAuthChallenge?
		) -> Effect<Action> {
			state.persona = persona
			state.authorizedDapp = authorizedDapp
			state.authorizedPersona = authorizedPersona

			let responsePersona = DappWalletInteractionPersona(
				identityAddress: persona.address,
				label: persona.displayName.value
			)

			if let signedAuthChallenge {
				guard
					// A **single** signature expected, since we sign auth with a single Persona.
					let entitySignature = signedAuthChallenge.entitySignatures.first,
					signedAuthChallenge.entitySignatures.count == 1
				else {
					return dismissEffect(for: state, errorKind: .failedToSignAuthChallenge, message: "Failed to serialize signature")
				}
				let proof = WalletToDappInteractionAuthProof(entitySignature: entitySignature)

				state.responseItems[item] = .remote(.auth(.loginWithChallenge(.init(
					persona: responsePersona,
					challenge: signedAuthChallenge.challenge,
					proof: proof
				))))

			} else {
				state.responseItems[item] = .remote(.auth(.loginWithoutChallenge(.init(
					persona: responsePersona
				))))
			}

			resetOngoingResponseItemsIfNeeded(for: &state)

			return autofillOngoingResponseItemsIfPossibleEffect(for: state)
		}

		func handleAccountPermission(_ item: State.AnyInteractionItem) -> Effect<Action> {
			let responseItem: State.AnyInteractionResponseItem = .local(.accountPermissionGranted)
			state.responseItems[item] = responseItem
			return continueEffect(for: &state)
		}

		func handleAccounts(
			_ item: State.AnyInteractionItem,
			_ choseAccounts: AccountPermissionChooseAccountsResult,
			_ accessKind: AccountPermissionChooseAccounts.State.AccessKind
		) -> Effect<Action> {
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
			_ persona: Persona
		) -> Effect<Action> {
			guard state.persona?.id == persona.id else {
				return .none
			}
			state.persona = persona
			let responsePersona = DappWalletInteractionPersona(persona: persona)
			for (request, response) in state.responseItems {
				// NB: native case paths should simplify this mutation logic a lot
				switch response {
				case let .remote(.auth(.loginWithChallenge(item))):
					state.responseItems[request] = .remote(.auth(.loginWithChallenge(.init(
						persona: responsePersona,
						challenge: item.challenge,
						proof: item.proof
					))))
				case .remote(.auth(.loginWithoutChallenge)):
					state.responseItems[request] = .remote(.auth(.loginWithoutChallenge(.init(
						persona: responsePersona
					))))
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

		func handleSignAndSubmitTX(
			_ item: State.AnyInteractionItem,
			_ txID: IntentHash
		) -> Effect<Action> {
			state.responseItems[item] = .remote(.send(.init(transactionIntentHash: txID)))
			return continueEffect(for: &state)
		}

		func handleSignAndSubmitTXFailed(
			_ error: TransactionFailure
		) -> Effect<Action> {
			let (errorKind, message) = error.errorKindAndMessage
			return dismissEffect(for: state, errorKind: errorKind, message: message)
		}

		let item = state.currentItem

		guard let action = childAction.action else { return .none }
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

		case let .personaDataPermission(.delegate(.continueButtonTapped(response))):
			state.responseItems[item] = .remote(.ongoingPersonaData(response))
			return continueEffect(for: &state)

		case let .oneTimePersonaData(.delegate(.continueButtonTapped(response))):
			state.responseItems[item] = .remote(.oneTimePersonaData(response))
			return continueEffect(for: &state)

		case let .chooseAccounts(.delegate(.continue(accessKind, chosenAccounts))):
			return handleAccounts(item, chosenAccounts, accessKind)

		case let .personaDataPermission(.delegate(.personaUpdated(persona))):
			return handlePersonaUpdated(&state, persona)

		case let .oneTimePersonaData(.delegate(.personaUpdated(persona))):
			return handlePersonaUpdated(&state, persona)

		case let .reviewTransaction(.delegate(.signedTXAndSubmittedToGateway(txID))):
			return handleSignAndSubmitTX(item, txID)

		case let .reviewTransaction(.delegate(.transactionCompleted(txID))):
			return .send(.delegate(.dismissWithSuccess(state.dappMetadata, txID)))

		case .reviewTransaction(.delegate(.dismiss)):
			return .send(.delegate(.dismiss))

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
			authorizedPersona.sharedPersonaData = .default
		}
		var identifiedReferencesToAuthorizedPersonas = authorizedDapp.referencesToAuthorizedPersonas.asIdentified()
		identifiedReferencesToAuthorizedPersonas[id: authorizedPersona.id] = authorizedPersona
		authorizedDapp.referencesToAuthorizedPersonas = identifiedReferencesToAuthorizedPersonas.elements
		state.authorizedDapp = authorizedDapp
		state.authorizedPersona = authorizedPersona
	}

	func autofillOngoingResponseItemsIfPossibleEffect(
		for state: State
	) -> Effect<Action> {
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
					let selectedAccounts = try? sharedAccounts.ids.compactMap({ sharedAccount in
						try allAccounts[id: .init(validatingAddress: sharedAccount.address)]
					}),
					selectedAccounts.count == sharedAccounts.ids.count
				else { return nil }

				return .init(
					requestItem: .remote(.ongoingAccounts(ongoingAccountsRequestItem)),
					numberOfAccountsRequested: sharedAccounts.request,
					accounts: selectedAccounts
				)
			}()

			payload.ongoingPersonaDataPayload = try await { () async throws -> InternalAction.AutofillOngoingResponseItemsPayload.PersonaDataPayload? in

				guard
					let personaDataRequested = state.ongoingPersonaDataRequestItem,
					let authorizedPersonaID = state.authorizedPersona?.id,
					let sharedPersonaData = state.authorizedPersona?.sharedPersonaData
				else {
					return nil
				}

				let allPersonas = try await personasClient.getPersonas()
				guard let persona = allPersonas[id: authorizedPersonaID] else { return nil }

				guard
					let responseItem = try? WalletToDappInteractionPersonaDataRequestResponseItem(
						personaDataRequested: personaDataRequested,
						personaData: persona.personaData
					)
				else {
					return nil
				}

				guard
					let updatedSharedPersonaData = try? SharedPersonaData(
						requested: personaDataRequested,
						persona: persona,
						provided: responseItem
					),
					sharedPersonaData.entryIDs.isSuperset(of: updatedSharedPersonaData.entryIDs)
				else {
					loggerGlobal.debug("Cannot autofill, have not shared fields earlier")
					return nil
				}

				let personaDataPayload = InternalAction.AutofillOngoingResponseItemsPayload.PersonaDataPayload(
					personaDataRequested: personaDataRequested,
					responseItem: responseItem
				)

				loggerGlobal.info("Autofilling with: \(personaDataPayload.responseItem)")

				return personaDataPayload
			}()

			await send(.internal(.autofillOngoingResponseItemsIfPossible(payload)))
		} catch: { error, _ in
			loggerGlobal.warning("Unable to autofill ongoing response, error: \(error)")
		}
	}
}

// MARK: - DappInteractionFlow.InternalAction.AutofillOngoingResponseItemsPayload.PersonaDataPayload
extension DappInteractionFlow.InternalAction.AutofillOngoingResponseItemsPayload {
	struct PersonaDataPayload: Sendable, Equatable {
		var personaDataRequested: DappToWalletInteractionPersonaDataRequestItem
		var responseItem: WalletToDappInteractionPersonaDataRequestResponseItem
	}
}

extension Collection where Element: PersonaDataEntryProtocol {
	func satisfies(_ requestedNumber: RequestedQuantity) -> Bool {
		switch requestedNumber.quantifier {
		case .atLeast:
			count >= requestedNumber.quantity
		case .exactly:
			count == requestedNumber.quantity
		}
	}
}

// MARK: - RequiredPersonaDataFieldsNotPresentInResponse
struct RequiredPersonaDataFieldsNotPresentInResponse: Swift.Error {
	let missingEntryKind: PersonaData.Entry.Kind
}

// MARK: - MissingPersonaDataFields
struct MissingPersonaDataFields: Swift.Error {}

extension DappInteractionFlow {
	func setAccountsResponse(
		to item: State.AnyInteractionItem,
		accessKind: AccountPermissionChooseAccounts.State.AccessKind,
		chosenAccounts: WalletToDappInteractionResponse.Accounts,
		into state: inout State
	) {
		switch accessKind {
		case .oneTime:
			state.responseItems[item] = .remote(.oneTimeAccounts(.init(accounts: chosenAccounts)))
		case .ongoing:
			state.responseItems[item] = .remote(.ongoingAccounts(.init(accounts: chosenAccounts)))
		}
	}

	func continueEffect(for state: inout State) -> Effect<Action> {
		if
			let nextRequest = state.interactionItems.first(where: { state.responseItems[$0] == nil }),
			let destination = Path.State(
				for: nextRequest,
				interaction: state.remoteInteraction,
				dappMetadata: state.dappMetadata,
				persona: state.persona
			)
		{
			if state.root == nil {
				state.root = destination
			} else if state.path.last != destination {
				return .run { send in
					/// For more information about that `sleep` and not setting it directly here please check [this discussion in Slack](https://rdxworks.slack.com/archives/C03QFAWBRNX/p1693395346047829?thread_ts=1693388110.800679&cid=C03QFAWBRNX)
					try? await clock.sleep(for: .milliseconds(250))
					await send(.internal(.delayedAppendToPath(destination)))
				}
			}
			return .none
		} else {
			return finishInteractionFlow(state)
		}
	}

	func finishInteractionFlow(_ state: State) -> Effect<Action> {
		guard let response = WalletToDappInteractionSuccessResponse(
			for: state.remoteInteraction,
			with: state.responseItems.values.compactMap(/State.AnyInteractionResponseItem.remote)
		) else {
			return .none // TODO: throw error (invalid response format)
		}

		return .run { [state] send in
			// Save login date, data fields, and ongoing accounts to Profile

			if let persona = state.persona {
				do {
					try await updatePersona(persona, state, responseItems: response.items)
				} catch {
					await send(.internal(.failedToUpdatePersonaAtEndOfFlow(
						persona: persona,
						response: response,
						metadata: state.dappMetadata
					)))
					return
				}
			}

			await send(.delegate(.submit(response, state.dappMetadata)))
		}
	}

	// Need to disable, since broken in swiftformat 0.52.7
	// swiftformat:disable redundantClosure

	func updatePersona(
		_ persona: Persona,
		_ state: State,
		responseItems: WalletToDappInteractionResponseItems
	) async throws {
		let networkID = await gatewaysClient.getCurrentNetworkID()
		var authorizedDapp: AuthorizedDapp = state.authorizedDapp ?? AuthorizedDapp(
			networkId: networkID,
			dappDefinitionAddress: state.dappMetadata.dAppDefinitionAddress,
			displayName: { () -> String? in
				switch state.dappMetadata {
				case let .ledger(ledger): ledger.name?.rawValue
				case .request, .wallet: nil
				}
			}(),
			referencesToAuthorizedPersonas: []
		)
		// This extraction is really verbose right now, but it should become a lot simpler with native case paths
		let sharedAccountsInfo: (DappInteractionNumberOfAccounts, [WalletInteractionWalletAccount])? = unwrap(
			// request
			{
				switch state.remoteInteraction.items {
				case let .authorizedRequest(items):
					items.ongoingAccounts?.numberOfAccounts
				default:
					nil
				}
			}(),
			// response
			{
				switch responseItems {
				case let .authorizedRequest(items):
					items.ongoingAccounts?.accounts
				default:
					nil
				}
			}()
		)

		let sharedPersonaDataInfo: (DappToWalletInteractionPersonaDataRequestItem, WalletToDappInteractionPersonaDataRequestResponseItem)? = unwrap(
			// request
			{
				switch state.remoteInteraction.items {
				case let .authorizedRequest(items):
					items.ongoingPersonaData
				default: nil
				}
			}(),
			// response
			{
				switch responseItems {
				case let .authorizedRequest(items):
					items.ongoingPersonaData
				default:
					nil
				}
			}()
		)

		let sharedAccounts: SharedToDappWithPersonaAccountAddresses? = if let (numberOfAccounts, accounts) = sharedAccountsInfo {
			.init(
				request: numberOfAccounts,
				ids: accounts.map(\.address)
			)
		} else {
			nil
		}

		let sharedPersonaData: SharedPersonaData?
		if let (requestedPersonaData, providedPersonData) = sharedPersonaDataInfo {
			sharedPersonaData = try SharedPersonaData(
				requested: requestedPersonaData,
				persona: persona,
				provided: providedPersonData
			)
			loggerGlobal.debug("updated persona to: \(String(describing: sharedPersonaData))")
		} else {
			sharedPersonaData = nil
		}

		@Dependency(\.date) var now
		let authorizedPersona: AuthorizedPersonaSimple = {
			if var authorizedPersona = state.authorizedPersona {
				authorizedPersona.lastLogin = now()
				if let sharedAccounts {
					authorizedPersona.sharedAccounts = sharedAccounts
				}
				if let sharedPersonaData {
					authorizedPersona.sharedPersonaData = sharedPersonaData
				}
				return authorizedPersona
			} else {
				return .init(
					identityAddress: persona.address,
					lastLogin: now(),
					sharedAccounts: sharedAccounts,
					sharedPersonaData: sharedPersonaData ?? .default
				)
			}
		}()
		var identifiedDeferencesToAuthorizedPersonas = authorizedDapp.referencesToAuthorizedPersonas.asIdentified()
		identifiedDeferencesToAuthorizedPersonas[id: authorizedPersona.id] = authorizedPersona
		authorizedDapp.referencesToAuthorizedPersonas = identifiedDeferencesToAuthorizedPersonas.elements
		try await authorizedDappsClient.updateOrAddAuthorizedDapp(authorizedDapp)
	}

	// swiftformat:enable redundantClosure

	func goBackEffect(for state: inout State) -> Effect<Action> {
		state.responseItems.removeLast()
		state.path.removeLast()
		return .none
	}

	func dismissEffect(
		for state: State,
		errorKind: DappWalletInteractionErrorType,
		message: String?
	) -> Effect<Action> {
		.send(.delegate(.dismissWithFailure(.init(
			interactionId: state.remoteInteraction.interactionId,
			error: errorKind,
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
				.sorted(by: \.priority)
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
	var action: DappInteractionFlow.Path.Action? {
		switch self {
		case let .root(action), let .path(.element(_, action)):
			action
		case .path(.popFrom), .path(.push):
			nil
		}
	}
}

extension DappInteractionFlow.Path.State {
	init?(
		for anyItem: DappInteractionFlow.State.AnyInteractionItem,
		interaction: DappInteractionFlow.State.RemoteInteraction,
		dappMetadata: DappMetadata,
		persona: Persona?
	) {
		self.item = anyItem
		switch anyItem {
		case let .remote(.auth(request)):
			switch request {
			case .loginWithChallenge, .loginWithoutChallenge:
				self.state = .login(.init(
					dappMetadata: dappMetadata,
					loginRequest: request
				))
			case .usePersona:
				return nil
			}

		case let .local(.accountPermissionRequested(numberOfAccounts)):
			self.state = .accountPermission(.init(
				dappMetadata: dappMetadata,
				numberOfAccounts: numberOfAccounts
			))

		case let .remote(.ongoingAccounts(item)):
			self.state = .chooseAccounts(.init(
				challenge: item.challenge,
				accessKind: .ongoing,
				dappMetadata: dappMetadata,
				numberOfAccounts: item.numberOfAccounts
			))

		case let .remote(.oneTimeAccounts(item)):
			self.state = .chooseAccounts(.init(
				challenge: item.challenge,
				accessKind: .oneTime,
				dappMetadata: dappMetadata,
				numberOfAccounts: item.numberOfAccounts
			))

		case let .remote(.oneTimePersonaData(item)):
			self.state = .oneTimePersonaData(.init(
				dappMetadata: dappMetadata,
				requested: item
			))

		case let .remote(.ongoingPersonaData(item)):
			guard let persona else {
				assertionFailure("Persona data request requires a persona.")
				return nil
			}

			self.state = .personaDataPermission(.init(
				dappMetadata: dappMetadata,
				personaID: persona.id,
				requested: item
			))

		case let .remote(.send(item)):
			self.state = .reviewTransaction(.init(
				unvalidatedManifest: item.unvalidatedManifest,
				nonce: .secureRandom(),
				signTransactionPurpose: .manifestFromDapp,
				message: item.message.map {
					Message.plaintext(string: $0)
				} ?? Message.none,
				waitsForTransactionToBeComitted: interaction.interactionId.isWalletAccountDepositSettingsInteraction,
				isWalletTransaction: interaction.interactionId.isWalletInteraction,
				proposingDappMetadata: dappMetadata.onLedger
			))
		}
	}
}

extension DappInteractionFlow.State {
	var usePersonaRequestItem: DappToWalletInteractionAuthUsePersonaRequestItem? {
		// NB: this should become a one liner with native case paths:
		// remoteInteractions.items[keyPath: \.request?.authorized?.auth?.usePersona?]
		guard
			case let .authorizedRequest(item) = remoteInteraction.items,
			case let .usePersona(item) = item.auth
		else {
			return nil
		}
		return item
	}

	var resetRequestItem: DappToWalletInteractionResetRequestItem? {
		// NB: this should become a one liner with native case paths:
		// remoteInteractions.items[keyPath: \.request?.authorized?.reset]
		guard
			case let .authorizedRequest(item) = remoteInteraction.items
		else {
			return nil
		}
		return item.reset
	}

	var ongoingAccountsRequestItem: DappToWalletInteractionAccountsRequestItem? {
		// NB: this should become a one liner with native case paths:
		// remoteInteractions.items[keyPath: \.request?.authorized?.ongoingAccounts]
		guard
			case let .authorizedRequest(item) = remoteInteraction.items
		else {
			return nil
		}
		return item.ongoingAccounts
	}

	var oneTimeAccountsRequestItem: DappToWalletInteractionAccountsRequestItem? {
		// NB: this should become a one liner with native case paths:
		// remoteInteractions.items[keyPath: \.request?.authorized?.oneTimeAccountsRequestItem]
		guard
			case let .authorizedRequest(item) = remoteInteraction.items
		else {
			return nil
		}
		return item.oneTimeAccounts
	}

	var oneTimePersonaDataRequestItem: DappToWalletInteractionPersonaDataRequestItem? {
		// NB: this should become a one liner with native case paths:
		// remoteInteractions.items[keyPath: \.request?.authorized?.oneTimePersonaDataRequestItem]
		guard
			case let .authorizedRequest(item) = remoteInteraction.items
		else {
			return nil
		}
		return item.oneTimePersonaData
	}

	var ongoingPersonaDataRequestItem: DappToWalletInteractionPersonaDataRequestItem? {
		// NB: this should become a one liner with native case paths:
		// remoteInteractions.items[keyPath: \.request?.authorized?.ongoingPersonaData]
		guard
			case let .authorizedRequest(item) = remoteInteraction.items
		else {
			return nil
		}
		return item.ongoingPersonaData
	}
}

// MARK: - MissingRequestedPersonaData
struct MissingRequestedPersonaData: Swift.Error {
	let kind: PersonaData.Entry.Kind
}

// MARK: - SavedPersonaDataInPersonaNumberOfEntriesSharedHasDiscrepancyWithRequested
struct SavedPersonaDataInPersonaNumberOfEntriesSharedHasDiscrepancyWithRequested: Swift.Error {
	let requestedNumber: RequestedQuantity
	let numberOfEntriesShared: Int
}

// MARK: - SavedPersonaDataInPersonaDoesNotContainRequestedPersonaData
struct SavedPersonaDataInPersonaDoesNotContainRequestedPersonaData: Swift.Error {
	let kind: PersonaData.Entry.Kind
}

// MARK: - SavedPersonaDataInPersonaDoesNotMatchWalletInteractionResponseItem
struct SavedPersonaDataInPersonaDoesNotMatchWalletInteractionResponseItem: Swift.Error {
	let kind: PersonaData.Entry.Kind
}

// MARK: - PersonaDataEntryNotFoundInResponse
struct PersonaDataEntryNotFoundInResponse: Swift.Error {
	let kind: PersonaData.Entry.Kind
}
