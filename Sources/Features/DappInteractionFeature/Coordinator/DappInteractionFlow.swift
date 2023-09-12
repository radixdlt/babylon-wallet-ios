import AccountsClient
import AuthorizedDappsClient
import Cryptography
import EngineKit
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
		var path: StackState<Destinations.State> = .init()

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
		case delayedAppendToPath(DappInteractionFlow.Destinations.State)

		struct AutofillOngoingResponseItemsPayload: Sendable, Equatable {
			struct AccountsPayload: Sendable, Equatable {
				var requestItem: DappInteractionFlow.State.AnyInteractionItem
				var numberOfAccountsRequested: DappInteraction.NumberOfAccounts
				var accounts: [Profile.Network.Account]
			}

			var ongoingAccountsPayload: AccountsPayload?

			var ongoingPersonaDataPayload: PersonaDataPayload?
		}

		case failedToUpdatePersonaAtEndOfFlow(
			persona: Profile.Network.Persona,
			response: P2P.Dapp.Response.WalletInteractionSuccessResponse,
			metadata: DappMetadata
		)
	}

	enum ChildAction: Sendable, Equatable {
		case root(Destinations.Action)
		case path(StackActionOf<Destinations>)
	}

	enum DelegateAction: Sendable, Equatable {
		case dismissWithFailure(P2P.Dapp.Response.WalletInteractionFailureResponse)
		case dismissWithSuccess(DappMetadata, TXID)
		case submit(P2P.Dapp.Response.WalletInteractionSuccessResponse, DappMetadata)
		case dismiss
	}

	struct Destinations: Sendable, Reducer {
		typealias State = RelayState<DappInteractionFlow.State.AnyInteractionItem, MainState>
		typealias Action = RelayAction<DappInteractionFlow.State.AnyInteractionItem, MainAction>

		enum MainState: Sendable, Hashable {
			case login(Login.State)
			case accountPermission(AccountPermission.State)
			case chooseAccounts(AccountPermissionChooseAccounts.State)
			case personaDataPermission(PersonaDataPermission.State)
			case oneTimePersonaData(OneTimePersonaData.State)
			case reviewTransaction(TransactionReview.State)
		}

		enum MainAction: Sendable, Equatable {
			case login(Login.Action)
			case accountPermission(AccountPermission.Action)
			case chooseAccounts(AccountPermissionChooseAccounts.Action)
			case personaDataPermission(PersonaDataPermission.Action)
			case oneTimePersonaData(OneTimePersonaData.Action)
			case reviewTransaction(TransactionReview.Action)
		}

		var body: some ReducerOf<Self> {
			Relay {
				EmptyReducer()
					.ifCaseLet(/MainState.login, action: /MainAction.login) {
						Login()
					}
					.ifCaseLet(/MainState.accountPermission, action: /MainAction.accountPermission) {
						AccountPermission()
					}
					.ifCaseLet(/MainState.chooseAccounts, action: /MainAction.chooseAccounts) {
						AccountPermissionChooseAccounts()
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

	var body: some ReducerOf<Self> {
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
					label: persona.displayName
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
					chosenAccounts: .withoutProofOfOwnership(.init(uniqueElements: ongoingAccountsWithoutProofOfOwnership.accounts)),
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
			_ persona: Profile.Network.Persona,
			_ authorizedDapp: Profile.Network.AuthorizedDapp?,
			_ authorizedPersona: Profile.Network.AuthorizedDapp.AuthorizedPersonaSimple?,
			_ signedAuthChallenge: SignedAuthChallenge?
		) -> Effect<Action> {
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
			_ persona: Profile.Network.Persona
		) -> Effect<Action> {
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

		func handleSignAndSubmitTX(
			_ item: State.AnyInteractionItem,
			_ txID: TXID
		) -> Effect<Action> {
			state.responseItems[item] = .remote(.send(.init(txID: txID)))
			return continueEffect(for: &state)
		}

		func handleSignAndSubmitTXFailed(
			_ error: TransactionFailure
		) -> Effect<Action> {
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

		case .reviewTransaction(.delegate(.userDismissedTransactionStatus)):
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
			authorizedPersona.sharedPersonaData = .init()
		}
		authorizedDapp.referencesToAuthorizedPersonas[id: authorizedPersona.id] = authorizedPersona
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
					let responseItem = try? P2P.Dapp.Response.WalletInteractionSuccessResponse.PersonaDataRequestResponseItem(
						personaDataRequested: personaDataRequested,
						personaData: persona.personaData
					)
				else {
					return nil
				}

				guard
					let updatedSharedPersonaData = try? Profile.Network.AuthorizedDapp.AuthorizedPersonaSimple.SharedPersonaData(
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
		var personaDataRequested: P2P.Dapp.Request.PersonaDataRequestItem
		var responseItem: P2P.Dapp.Response.WalletInteractionSuccessResponse.PersonaDataRequestResponseItem
	}
}

extension Collection where Element: PersonaDataEntryProtocol {
	func satisfies(_ requestedNumber: RequestedNumber) -> Bool {
		switch requestedNumber.quantifier {
		case .atLeast:
			return count >= requestedNumber.quantity
		case .exactly:
			return count == requestedNumber.quantity
		}
	}
}

// MARK: - RequiredPersonaDataFieldsNotPresentInResponse
struct RequiredPersonaDataFieldsNotPresentInResponse: Swift.Error {
	let missingEntryKind: PersonaData.Entry.Kind
}

// MARK: - MissingPersonaDataFields
struct MissingPersonaDataFields: Swift.Error {}

extension Profile.Network.AuthorizedDapp.AuthorizedPersonaSimple.SharedPersonaData {
	init(
		requested: P2P.Dapp.Request.PersonaDataRequestItem,
		persona: Profile.Network.Persona,
		provided: P2P.Dapp.Response.WalletInteractionSuccessResponse.PersonaDataRequestResponseItem
	) throws {
		func extractField<PersonaDataEntry>(
			personaDataEntryKind: PersonaData.Entry.Kind,
			isRequested isRequestedKeyPath: KeyPath<P2P.Dapp.Request.PersonaDataRequestItem, Bool?>,
			personaData personaDataKeyPath: KeyPath<PersonaData, PersonaData.IdentifiedEntry<PersonaDataEntry>?>,
			provided providedKeyPath: KeyPath<P2P.Dapp.Response.WalletInteractionSuccessResponse.PersonaDataRequestResponseItem, PersonaDataEntry?>
		) throws -> PersonaDataEntryID? where PersonaDataEntry: Hashable & PersonaDataEntryProtocol {
			// Check if incoming Dapp requested this persona data entry kind
			guard requested[keyPath: isRequestedKeyPath] == true else { return nil }

			// Check if PersonaData in Persona contains the entry
			guard let entrySavedInPersona = persona.personaData[keyPath: personaDataKeyPath] else {
				loggerGlobal.error("PersonaData in Persona does not contain expected requested persona data entry of kind: \(personaDataEntryKind)")
				throw MissingRequestedPersonaData(kind: personaDataEntryKind)
			}

			// Check if response we are about to send back to dapp contains a value of expected kind
			guard let providedEntry = provided[keyPath: providedKeyPath] else {
				loggerGlobal.error("Discrepancy, the response we are about to send back to dapp does not contain the requested persona data entry of kind: \(personaDataEntryKind)")
				throw PersonaDataEntryNotFoundInResponse(kind: personaDataEntryKind)
			}

			// Check if response we are about to send back equals to the one saved in Profile
			guard providedEntry == entrySavedInPersona.value else {
				loggerGlobal.error("Discrepancy, the value of the persona data entry does not match what is saved in profile: [response to dapp]: '\(providedEntry)' != '\(entrySavedInPersona.value)' [saved in Profile]")
				throw SavedPersonaDataInPersonaDoesNotMatchWalletInteractionResponseItem(
					kind: personaDataEntryKind
				)
			}

			// Return the id of the entry
			return entrySavedInPersona.id
		}

		func extractSharedCollection<PersonaDataElement>(
			personaDataEntryKind: PersonaData.Entry.Kind,
			personaData personaDataKeyPath: KeyPath<PersonaData, PersonaData.CollectionOfIdentifiedEntries<PersonaDataElement>>,
			provided providedKeyPath: KeyPath<P2P.Dapp.Response.WalletInteractionSuccessResponse.PersonaDataRequestResponseItem, OrderedSet<PersonaDataElement>?>,
			requested requestedKeyPath: KeyPath<P2P.Dapp.Request.PersonaDataRequestItem, RequestedNumber?>
		) throws -> SharedCollection?
			where
			PersonaDataElement: Sendable & Hashable & Codable & BasePersonaDataEntryProtocol
		{
			// Check if incoming Dapp requests the persona data entry kind
			guard
				let numberOfRequestedElements = requested[keyPath: requestedKeyPath],
				numberOfRequestedElements.quantity > 0
			else {
				// Incoming Dapp request did not ask for access to this kind
				return nil
			}

			// Read out the entries saved in persona (could have been just updated, part of the flow)
			let entriesSavedInPersona = persona.personaData[keyPath: personaDataKeyPath]

			// Ensure the response we plan to send back to Dapp contains the persona data entries as well (else discrepancy in DappInteractionFlow)
			guard let providedEntries = provided[keyPath: providedKeyPath] else {
				loggerGlobal.error("Discrepancy in DappInteractionFlow, Dapp requests access to persona data entry of kind: \(personaDataEntryKind), specifically: \(numberOfRequestedElements) many, which where in fact found in PersonaData saved in Persona, however, the response we are aboutto send back to Dapp does not contain it.")
				throw SavedPersonaDataInPersonaDoesNotContainRequestedPersonaData(kind: personaDataEntryKind)
			}

			// Check all entries in response are found in persona
			guard Set(entriesSavedInPersona.map(\.value)).isSuperset(of: Set(providedEntries)) else {
				loggerGlobal.error("Discrepancy in DappInteractionFlow, response back to dapp contains entries which are not in PersonaData in Persona.")
				throw SavedPersonaDataInPersonaDoesNotMatchWalletInteractionResponseItem(
					kind: personaDataEntryKind
				)
			}

			return try Profile.Network.AuthorizedDapp.AuthorizedPersonaSimple.SharedPersonaData.SharedCollection(
				ids: OrderedSet(validating: entriesSavedInPersona.map(\.id)),
				forRequest: numberOfRequestedElements
			)
		}

		try self.init(
			name: extractField(
				personaDataEntryKind: .fullName,
				isRequested: \.isRequestingName,
				personaData: \.name,
				provided: \.name
			),
			dateOfBirth: nil, // FIXME: When P2P.Dapp.Requests and Response support it
			companyName: nil, // FIXME: When P2P.Dapp.Requests and Response support it
			emailAddresses: extractSharedCollection(
				personaDataEntryKind: .emailAddress,
				personaData: \.emailAddresses,
				provided: \.emailAddresses,
				requested: \.numberOfRequestedEmailAddresses
			),
			phoneNumbers: extractSharedCollection(
				personaDataEntryKind: .phoneNumber,
				personaData: \.phoneNumbers,
				provided: \.phoneNumbers,
				requested: \.numberOfRequestedPhoneNumbers
			),
			urls: nil, // FIXME: When P2P.Dapp.Requests and Response support it
			postalAddresses: nil, // FIXME: When P2P.Dapp.Requests and Response support it
			creditCards: nil // FIXME: When P2P.Dapp.Requests and Response support it
		)
	}
}

extension P2P.Dapp.Response.WalletInteractionSuccessResponse.PersonaDataRequestResponseItem {
	init(
		personaDataRequested requested: P2P.Dapp.Request.PersonaDataRequestItem,
		personaData: PersonaData
	) throws {
		func extractEntry<T>(
			_ personaDataKeyPath: KeyPath<PersonaData, PersonaData.IdentifiedEntry<T>?>,
			isRequested isRequestedKeyPath: KeyPath<P2P.Dapp.Request.PersonaDataRequestItem, Bool?>
		) -> T? where T: PersonaDataEntryProtocol {
			// Check if incoming Dapp requested this persona data entry kind
			guard requested[keyPath: isRequestedKeyPath] == true else { return nil }
			guard let personaDataEntry = personaData[keyPath: personaDataKeyPath] else { return nil }
			return personaDataEntry.value
		}

		func extractEntries<T>(
			_ personaDataKeyPath: KeyPath<PersonaData, PersonaData.CollectionOfIdentifiedEntries<T>>,
			requested requestedKeyPath: KeyPath<P2P.Dapp.Request.PersonaDataRequestItem, RequestedNumber?>
		) throws -> OrderedSet<T>? where T: Hashable & PersonaDataEntryProtocol {
			// Check if incoming Dapp requests the persona data entry kind
			guard
				let numberOfRequestedElements = requested[keyPath: requestedKeyPath],
				numberOfRequestedElements.quantity > 0
			else {
				// Incoming Dapp request did not ask for access to this kind
				return nil
			}
			let personaDataEntries = personaData[keyPath: personaDataKeyPath]
			let personaDataEntriesOrderedSet = try OrderedSet<T>(validating: personaDataEntries.map(\.value))

			guard personaDataEntriesOrderedSet.satisfies(numberOfRequestedElements) else {
				return nil
			}
			return personaDataEntriesOrderedSet
		}

		try self.init(
			name: extractEntry(\.name, isRequested: \.isRequestingName),
			dateOfBirth: nil, // FIXME: When P2P.Dapp.Requests and Response support it
			companyName: nil, // FIXME: When P2P.Dapp.Requests and Response support it
			emailAddresses: extractEntries(\.emailAddresses, requested: \.numberOfRequestedEmailAddresses),
			phoneNumbers: extractEntries(\.phoneNumbers, requested: \.numberOfRequestedPhoneNumbers),
			urls: nil, // FIXME: When P2P.Dapp.Requests and Response support it
			postalAddresses: nil, // FIXME: When P2P.Dapp.Requests and Response support it
			creditCards: nil // FIXME: When P2P.Dapp.Requests and Response support it
		)
	}
}

extension DappInteractionFlow {
	func setAccountsResponse(
		to item: State.AnyInteractionItem,
		accessKind: AccountPermissionChooseAccounts.State.AccessKind,
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

	func continueEffect(for state: inout State) -> Effect<Action> {
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
		guard let response = P2P.Dapp.Response.WalletInteractionSuccessResponse(
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
				case .request, .wallet: return nil
				}
			}()
		)
		// This extraction is really verbose right now, but it should become a lot simpler with native case paths
		let sharedAccountsInfo: (P2P.Dapp.Request.NumberOfAccounts, [P2P.Dapp.Response.WalletAccount])? = unwrap(
			// request
			{
				switch state.remoteInteraction.items {
				case let .request(.authorized(items)):
					return items.ongoingAccounts?.numberOfAccounts
				default:
					return nil
				}
			}(),
			// response
			{
				switch responseItems {
				case let .request(.authorized(items)):
					return items.ongoingAccounts?.accounts
				default:
					return nil
				}
			}()
		)

		let sharedPersonaDataInfo: (P2P.Dapp.Request.PersonaDataRequestItem, P2P.Dapp.Response.WalletInteractionSuccessResponse.PersonaDataRequestResponseItem)? = unwrap(
			// request
			{
				switch state.remoteInteraction.items {
				case let .request(.authorized(items)):
					return items.ongoingPersonaData
				default: return nil
				}
			}(),
			// response
			{
				switch responseItems {
				case let .request(.authorized(items)):
					return items.ongoingPersonaData
				default:
					return nil
				}
			}()
		)

		let sharedAccounts: Profile.Network.AuthorizedDapp.AuthorizedPersonaSimple.SharedAccounts?
		if let (numberOfAccounts, accounts) = sharedAccountsInfo {
			sharedAccounts = try .init(
				ids: OrderedSet(accounts.map(\.address)),
				forRequest: numberOfAccounts
			)
		} else {
			sharedAccounts = nil
		}

		let sharedPersonaData: Profile.Network.AuthorizedDapp.AuthorizedPersonaSimple.SharedPersonaData?
		if let (requestedPersonaData, providedPersonData) = sharedPersonaDataInfo {
			sharedPersonaData = try Profile.Network.AuthorizedDapp.AuthorizedPersonaSimple.SharedPersonaData(
				requested: requestedPersonaData,
				persona: persona,
				provided: providedPersonData
			)
			loggerGlobal.debug("updated persona to: \(String(describing: sharedPersonaData))")
		} else {
			sharedPersonaData = nil
		}

		@Dependency(\.date) var now
		let authorizedPersona: Profile.Network.AuthorizedDapp.AuthorizedPersonaSimple = {
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
					sharedPersonaData: sharedPersonaData ?? .init()
				)
			}
		}()
		authorizedDapp.referencesToAuthorizedPersonas[id: authorizedPersona.id] = authorizedPersona
		try await authorizedDappsClient.updateOrAddAuthorizedDapp(authorizedDapp)
	}

	func goBackEffect(for state: inout State) -> Effect<Action> {
		state.responseItems.removeLast()
		state.path.removeLast()
		return .none
	}

	func dismissEffect(
		for state: State,
		errorKind: P2P.Dapp.Response.WalletInteractionFailureResponse.ErrorType,
		message: String?
	) -> Effect<Action> {
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
	var itemAndAction: (DappInteractionFlow.State.AnyInteractionItem, DappInteractionFlow.Destinations.MainAction)? {
		switch self {
		case let .root(.relay(item, action)), let .path(.element(_, .relay(item, action))):
			return (item, action)

		case .path(.popFrom), .path(.push):
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
				numberOfAccounts: item.numberOfAccounts
			)))

		case let .remote(.oneTimeAccounts(item)):
			self = .relayed(anyItem, with: .chooseAccounts(.init(
				challenge: item.challenge,
				accessKind: .oneTime,
				dappMetadata: dappMetadata,
				numberOfAccounts: item.numberOfAccounts
			)))

		case let .remote(.oneTimePersonaData(item)):
			self = .relayed(anyItem, with: .oneTimePersonaData(.init(
				dappMetadata: dappMetadata,
				requested: item
			)))

		case let .remote(.ongoingPersonaData(item)):
			guard let persona else {
				assertionFailure("Persona data request requires a persona.")
				return nil
			}

			self = .relayed(anyItem, with: .personaDataPermission(.init(
				dappMetadata: dappMetadata,
				personaID: persona.id,
				requested: item
			)))

		case let .remote(.send(item)):
			self = .relayed(anyItem, with: .reviewTransaction(.init(
				transactionManifest: item.transactionManifest,
				nonce: .secureRandom(),
				signTransactionPurpose: .manifestFromDapp,
				message: item.message.map {
					Message.plainText(value: .init(mimeType: "text", message: .str(value: $0)))
				} ?? .none
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

// MARK: - MissingRequestedPersonaData
struct MissingRequestedPersonaData: Swift.Error {
	let kind: PersonaData.Entry.Kind
}

// MARK: - SavedPersonaDataInPersonaNumberOfEntriesSharedHasDiscrepancyWithRequested
struct SavedPersonaDataInPersonaNumberOfEntriesSharedHasDiscrepancyWithRequested: Swift.Error {
	let requestedNumber: RequestedNumber
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
