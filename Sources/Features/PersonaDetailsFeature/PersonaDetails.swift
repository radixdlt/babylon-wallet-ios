import AuthorizedDappsClient
import EditPersonaFeature
import FeaturePrelude
import GatewayAPI
import ROLAClient
import TransactionReviewFeature

// MARK: - PersonaDetails
public struct PersonaDetails: Sendable, FeatureReducer {
	@Dependency(\.gatewayAPIClient) var gatewayAPIClient
	@Dependency(\.personasClient) var personasClient
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.authorizedDappsClient) var authorizedDappsClient

	public typealias Store = StoreOf<Self>

	@Dependency(\.rolaClient) var rolaClient

	public init() {}

	// MARK: - State

	public struct State: Sendable, Hashable {
		public var mode: Mode

		public enum Mode: Sendable, Hashable {
			case general(Profile.Network.Persona, dApps: IdentifiedArrayOf<DappInfo>)
			case dApp(Profile.Network.AuthorizedDappDetailed, persona: Profile.Network.AuthorizedPersonaDetailed)

			var id: Profile.Network.Persona.ID {
				switch self {
				case let .general(persona, _): return persona.id
				case let .dApp(_, persona: persona): return persona.id
				}
			}
		}

		public struct DappInfo: Sendable, Hashable, Identifiable {
			public let id: Profile.Network.AuthorizedDapp.ID
			public var thumbnail: URL?
			public let displayName: String

			public init(dApp: Profile.Network.AuthorizedDapp) {
				self.id = dApp.id
				self.thumbnail = nil
				self.displayName = dApp.displayName.rawValue
			}
		}

		@PresentationState
		var destination: Destination.State? = nil

		var identityAddress: IdentityAddress {
			mode.id
		}

		#if DEBUG
		public var createAndUploadAuthKeyButtonState: ControlState
		#endif

		public init(_ mode: Mode) {
			self.mode = mode

			#if DEBUG
			let hasAuthenticationSigningKey: Bool
			switch mode {
			case let .general(persona, _):
				hasAuthenticationSigningKey = persona.hasAuthenticationSigningKey
			case let .dApp(_, persona):
				hasAuthenticationSigningKey = persona.hasAuthenticationSigningKey
			}
			self.createAndUploadAuthKeyButtonState = hasAuthenticationSigningKey ? .disabled : .enabled
			#endif
		}
	}

	// MARK: - Action

	public enum ViewAction: Sendable, Equatable {
		case appeared
		case accountTapped(AccountAddress)
		case dAppTapped(Profile.Network.AuthorizedDapp.ID)
		case editPersonaTapped
		case editAccountSharingTapped
		case deauthorizePersonaTapped
		#if DEBUG
		case createAndUploadAuthKeyButtonTapped
		#endif
	}

	public enum ChildAction: Sendable, Equatable {
		case destination(PresentationAction<Destination.Action>)
	}

	public enum DelegateAction: Sendable, Equatable {
		case personaDeauthorized
		case personaChanged(Profile.Network.Persona.ID)
	}

	public enum InternalAction: Sendable, Equatable {
		case editablePersonaFetched(Profile.Network.Persona)
		case reloaded(State.Mode)
		case dAppsUpdated(IdentifiedArrayOf<State.DappInfo>)
		case callDone(updateControlState: WritableKeyPath<State, ControlState>, changeTo: ControlState)
		case hideLoader(updateControlState: WritableKeyPath<State, ControlState>)

		case reviewCreateAuthKeyTransaction(TransactionManifest)
	}

	// MARK: - Destination

	public struct Destination: ReducerProtocol {
		public enum State: Equatable, Hashable {
			case editPersona(EditPersona.State)
			case createAuthKeyTransaction(TransactionReview.State)

			case confirmForgetAlert(AlertState<Action.ConfirmForgetAlert>)
		}

		public enum Action: Equatable {
			case editPersona(EditPersona.Action)
			case createAuthKeyTransaction(TransactionReview.Action)

			case confirmForgetAlert(ConfirmForgetAlert)
			public enum ConfirmForgetAlert: Sendable, Equatable {
				case confirmTapped
				case cancelTapped
			}
		}

		public var body: some ReducerProtocolOf<Self> {
			Scope(state: /State.editPersona, action: /Action.editPersona) {
				EditPersona()
			}
			Scope(state: /State.createAuthKeyTransaction, action: /Action.createAuthKeyTransaction) {
				TransactionReview()
			}
		}
	}

	// MARK: - Reducer

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.ifLet(\.$destination, action: /Action.child .. ChildAction.destination) {
				Destination()
			}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .destination(.presented(.editPersona(.delegate(.personaSaved(persona))))):
			guard persona.id == state.mode.id else { return .none }
			return .run { [mode = state.mode] send in
				let updated = try await reload(in: mode)
				await send(.internal(.reloaded(updated)))
				await send(.delegate(.personaChanged(persona.id)))
			} catch: { error, _ in
				loggerGlobal.error("Failed to reload, error: \(error)")
			}

		case .destination(.presented(.confirmForgetAlert(.confirmTapped))):
			guard case let .dApp(dApp, persona: persona) = state.mode else {
				return .none
			}
			let (personaID, dAppID, networkID) = (persona.id, dApp.dAppDefinitionAddress, dApp.networkID)
			return .run { send in
				try await authorizedDappsClient.deauthorizePersonaFromDapp(personaID, dAppID, networkID)
				await send(.delegate(.personaDeauthorized))
			} catch: { error, _ in
				loggerGlobal.error("Failed to deauthorize persona \(personaID) from dApp \(dAppID), error: \(error)")
				errorQueue.schedule(error)
			}

		case .destination:
			return .none
		}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			guard case let .general(_, dApps) = state.mode else { return .none }
			return .task {
				await .internal(.dAppsUpdated(addingDappMetadata(to: dApps)))
			}

		#if DEBUG
		case .createAndUploadAuthKeyButtonTapped:
			return .run { [identityAddress = state.identityAddress] send in
				let manifest = try await rolaClient.createAuthSigningKeyForPersonaIfNeeded(.init(identityAddress: identityAddress))
				await send(.internal(.reviewCreateAuthKeyTransaction(manifest)))
			} catch: { error, _ in
				loggerGlobal.error("Failed to create transaction for auth key creation, error: \(error)")
				errorQueue.schedule(error)
			}
		#endif

		case let .accountTapped(address):
			return .none

		case let .dAppTapped(dAppID):
			return .none

		case .editPersonaTapped:
			switch state.mode {
			case let .general(persona, _):
				return .send(.internal(.editablePersonaFetched(persona)))

			case let .dApp(_, persona: persona):
				return .run { send in
					let persona = try await personasClient.getPersona(id: persona.id)
					await send(.internal(.editablePersonaFetched(persona)))
				} catch: { error, _ in
					loggerGlobal.error("Could not get persona \(persona.id), error: \(error)")
					errorQueue.schedule(error)
				}
			}

		case .editAccountSharingTapped:
			return .none

		case .deauthorizePersonaTapped:
			state.destination = .confirmForgetAlert(.confirmForget)
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .editablePersonaFetched(persona):
			switch state.mode {
			case .general:
				state.destination = .editPersona(.init(mode: .edit, persona: persona))
			case let .dApp(_, detailedPersona):
				let fieldIDs = (detailedPersona.sharedFields ?? []).ids
				state.destination = .editPersona(.init(mode: .dapp(requiredFieldIDs: Set(fieldIDs)), persona: persona))
			}

			return .none

		case let .reviewCreateAuthKeyTransaction(manifest):
			state.destination = .createAuthKeyTransaction(.init(transactionManifest: manifest, message: nil))
			return .none

		case let .dAppsUpdated(dApps):
			guard case let .general(persona, _) = state.mode else { return .none }
			state.mode = .general(persona, dApps: dApps)
			return .none

		case let .reloaded(mode):
			state.mode = mode
			return .none

		case let .hideLoader(controlStateKeyPath):
			state[keyPath: controlStateKeyPath] = .enabled
			return .none

		case let .callDone(controlStateKeyPath, newState):
			state[keyPath: controlStateKeyPath] = newState
			return .none
		}
	}

	private func reload(in mode: State.Mode) async throws -> State.Mode {
		switch mode {
		case let .dApp(dApp, persona: persona):
			let updatedDapp = try await authorizedDappsClient.getDetailedDapp(dApp.dAppDefinitionAddress)
			guard let updatedPersona = updatedDapp.detailedAuthorizedPersonas[id: persona.id] else {
				throw ReloadError.personaNotPresentInDapp(persona.id, updatedDapp.dAppDefinitionAddress)
			}
			return .dApp(updatedDapp, persona: updatedPersona)
		case let .general(oldPersona, _):
			let persona = try await personasClient.getPersona(id: oldPersona.id)
			let dApps = try await authorizedDappsClient.getDappsAuthorizedByPersona(oldPersona.id)
				.map(State.DappInfo.init)

			return await .general(persona, dApps: addingDappMetadata(to: .init(uniqueElements: dApps)))
		}
	}

	private func addingDappMetadata(to dApps: State.DappsSection) async -> State.DappsSection {
		var dApps = dApps
		for dApp in dApps {
			do {
				let metadata = try await gatewayAPIClient.getDappMetadata(dApp.id)
				dApps[id: dApp.id]?.thumbnail = metadata.iconURL
			} catch {
				loggerGlobal.error("Failed to load dApp metadata, error: \(error)")
			}
		}
		return dApps
	}

	private func call(
		buttonState: WritableKeyPath<State, ControlState>,
		into state: inout State,
		onSuccess: ControlState,
		call: @escaping @Sendable (IdentityAddress) async throws -> Void
	) -> EffectTask<Action> {
		state[keyPath: buttonState] = .loading(.local)
		return .run { [address = state.mode.id] send in
			try await call(address)
			await send(.internal(.callDone(updateControlState: buttonState, changeTo: onSuccess)))
		} catch: { error, send in
			await send(.internal(.hideLoader(updateControlState: buttonState)))
			if !Task.isCancelled {
				errorQueue.schedule(error)
			}
		}
	}

	enum ReloadError: Error {
		case personaNotPresentInDapp(Profile.Network.Persona.ID, Profile.Network.AuthorizedDapp.ID)
	}
}

extension AlertState<PersonaDetails.Destination.Action.ConfirmForgetAlert> {
	static var confirmForget: AlertState {
		AlertState {
			TextState(L10n.PersonaDetails.deauthorizePersonaAlertTitle)
		} actions: {
			ButtonState(role: .destructive, action: .confirmTapped) {
				TextState(L10n.PersonaDetails.deauthorizePersonaAlertConfirm)
			}
			ButtonState(role: .cancel, action: .cancelTapped) {
				TextState(L10n.PersonaDetails.deauthorizePersonaAlertCancel)
			}
		} message: {
			TextState(L10n.PersonaDetails.deauthorizePersonaAlertMessage)
		}
	}
}
