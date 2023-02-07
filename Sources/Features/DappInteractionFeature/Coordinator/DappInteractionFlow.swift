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

		@PresentationState
		var personaNotFoundErrorAlert: AlertState<ViewAction.PersonaNotFoundErrorAlertAction>? = nil

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
		case personaNotFoundErrorAlert(PresentationAction<AlertState<PersonaNotFoundErrorAlertAction>, PersonaNotFoundErrorAlertAction>)

		enum PersonaNotFoundErrorAlertAction: Sendable, Equatable {
			case cancelButtonTapped
		}
	}

	enum InternalAction: Sendable, Equatable {
		case usePersona(P2P.FromDapp.WalletInteraction.AuthUsePersonaRequestItem, OnNetwork.Persona)
		case presentPersonaNotFoundErrorAlert
	}

	enum ChildAction: Sendable, Equatable {
		case root(Destinations.Action)
		case path(NavigationActionOf<Destinations>)
	}

	enum DelegateAction: Sendable, Equatable {
		case dismiss(P2P.ToDapp.WalletInteractionFailureResponse)
		case submit(P2P.ToDapp.WalletInteractionSuccessResponse)
	}

	struct Destinations: Sendable, ReducerProtocol {
		typealias State = RelayState<DappInteractionFlow.State.AnyInteractionItem, MainState>
		typealias Action = RelayAction<DappInteractionFlow.State.AnyInteractionItem, MainAction>

		enum MainState: Sendable, Hashable {
			case login(LoginRequest.State)
			case permission(Permission.State)
			case chooseAccounts(ChooseAccounts.State)
			case signAndSubmitTransaction(TransactionSigning.State)
		}

		enum MainAction: Sendable, Equatable {
			case login(LoginRequest.Action)
			case permission(Permission.Action)
			case chooseAccounts(ChooseAccounts.Action)
			case signAndSubmitTransaction(TransactionSigning.Action)
		}

		var body: some ReducerProtocolOf<Self> {
			Relay {
				Scope(state: /MainState.login, action: /MainAction.login) {
					LoginRequest()
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
				return .run { [usePersonaItem] send in
					if let persona = try await profileClient.getPersonas().first(by: .init(address: usePersonaItem.identityAddress)) {
						await send(.internal(.usePersona(usePersonaItem, persona)))
					} else {
						await send(.internal(.presentPersonaNotFoundErrorAlert))
					}
				}
			} else {
				return .none
			}
		case let .personaNotFoundErrorAlert(action):
			state.personaNotFoundErrorAlert = nil
			switch action {
			case .dismiss, .present:
				return .none
			case .presented(.cancelButtonTapped):
				// FIXME: .rejectedByUser should perhaps be a different, more specialized error (.invalidSpecifiedPersona?)
				return dismissEffect(for: state, errorKind: .rejectedByUser, message: nil)
			}
		case .closeButtonTapped:
			return dismissEffect(for: state, errorKind: .rejectedByUser, message: nil)
		case .backButtonTapped:
			return goBackEffect(for: &state)
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .usePersona(item, persona):
			state.responseItems[.remote(.auth(.usePersona(item)))] = .remote(.auth(.usePersona(.init(identityAddress: persona.address.address))))
			// TODO: look ahead at ongoing accounts request and fill them out if possible
			return continueEffect(for: &state)
		case .presentPersonaNotFoundErrorAlert:
			state.personaNotFoundErrorAlert = .init(
				title: { TextState(L10n.App.errorOccurredTitle) },
				actions: {
					ButtonState(role: .cancel, action: .send(.cancelButtonTapped)) {
						TextState(L10n.DApp.Request.SpecifiedPersonaNotFoundError.cancelButtonTitle)
					}
				},
				message: { TextState(L10n.DApp.Request.SpecifiedPersonaNotFoundError.message) }
			)
			return .none
		}
	}

	func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case
			let .root(.relay(item, .login(.delegate(.continueButtonTapped(persona, authorizedPersona))))),
			let .path(.element(_, .relay(item, .login(.delegate(.continueButtonTapped(persona, authorizedPersona)))))):
			// TODO: look ahead at ongoing accounts request and fill them out if possible
			let responseItem: State.AnyInteractionResponseItem = .remote(.auth(.login(.withoutChallenge(.init(
				identityAddress: persona.address.address
			)))))
			state.responseItems[item] = responseItem
			return continueEffect(for: &state)
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
			let .root(.relay(item, .signAndSubmitTransaction(.delegate(.failed(error))))),
			let .path(.element(_, .relay(item, .signAndSubmitTransaction(.delegate(.failed(error)))))):
			let (errorKind, message) = error.errorKindAndMessage
			return dismissEffect(for: state, errorKind: errorKind, message: message)
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

extension ApproveTransactionFailure {
	var errorKindAndMessage: (errorKind: P2P.ToDapp.WalletInteractionFailureResponse.ErrorType, message: String?) {
		switch self {
		case let .transactionFailure(transactionFailure):
			switch transactionFailure {
			case let .failedToCompileOrSign(error):
				switch error {
				case .failedToCompileNotarizedTXIntent, .failedToCompileTXIntent, .failedToCompileSignedTXIntent, .failedToGenerateTXId:
					return (errorKind: .failedToCompileTransaction, message: nil)
				case .failedToSignIntentWithAccountSigners, .failedToSignSignedCompiledIntentWithNotarySigner, .failedToConvertNotarySignature, .failedToConvertAccountSignatures:
					return (errorKind: .failedToSignTransaction, message: nil)
				}
			case let .failedToPrepareForTXSigning(error):
				return (errorKind: .failedToPrepareTransaction, message: error.errorDescription)

			case let .failedToSubmit(submissionError):

				switch submissionError {
				case .failedToSubmitTX:
					return (errorKind: .failedToSubmitTransaction, message: nil)
				case let .invalidTXWasSubmittedButNotSuccessful(txID, status: .rejected):
					return (errorKind: .submittedTransactionHasRejectedTransactionStatus, message: "TXID: \(txID)")
				case let .invalidTXWasSubmittedButNotSuccessful(txID, status: .failed):
					return (errorKind: .submittedTransactionHasFailedTransactionStatus, message: "TXID: \(txID)")
				case let .failedToPollTX(txID, _):
					return (errorKind: .failedToPollSubmittedTransaction, message: "TXID: \(txID)")
				case let .invalidTXWasDuplicate(txID):
					return (errorKind: .submittedTransactionWasDuplicate, message: "TXID: \(txID)")
				case let .failedToGetTransactionStatus(txID, _):
					return (errorKind: .failedToPollSubmittedTransaction, message: "TXID: \(txID)")
				}
			}

		case let .prepareTransactionFailure(prepareTransactionFailure):
			switch prepareTransactionFailure {
			case let .addTransactionFee(addTransactionFeeError):
				return (errorKind: .failedToPrepareTransaction, message: addTransactionFeeError.localizedDescription)
			}
		}
	}
}
