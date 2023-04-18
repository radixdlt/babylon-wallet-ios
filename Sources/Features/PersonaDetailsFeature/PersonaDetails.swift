import AuthorizedDappsClient
import EditPersonaFeature
import FeaturePrelude

// MARK: - PersonaDetails
public struct PersonaDetails: Sendable, FeatureReducer {
	@Dependency(\.personasClient) var personasClient
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.authorizedDappsClient) var authorizedDappsClient

	public typealias Store = StoreOf<Self>

	public init() {}

	// MARK: - State

	public struct State: Sendable, Hashable {
		public var mode: Mode

		public enum Mode: Sendable, Hashable {
			case general(Profile.Network.Persona)
			case dApp(Profile.Network.AuthorizedDappDetailed, persona: Profile.Network.AuthorizedPersonaDetailed)

			var id: Profile.Network.Persona.ID {
				switch self {
				case let .general(persona): return persona.id
				case let .dApp(_, persona: persona): return persona.id
				}
			}

			var networkID: NetworkID {
				switch self {
				case let .general(persona): return persona.networkID
				case let .dApp(dApp, _): return dApp.networkID
				}
			}
		}

		@PresentationState
		public var confirmForgetAlert: AlertState<ViewAction.ConfirmForgetAlert>? = nil

		@PresentationState
		public var editPersona: EditPersona.State? = nil

		public init(_ mode: Mode) {
			self.mode = mode
		}
	}

	// MARK: - Action

	public enum ViewAction: Sendable, Equatable {
		case accountTapped(AccountAddress)
		case editPersonaTapped
		case editAccountSharingTapped
		case deauthorizePersonaTapped
		case confirmForgetAlert(PresentationAction<ConfirmForgetAlert>)

		public enum ConfirmForgetAlert: Sendable, Equatable {
			case confirmTapped
			case cancelTapped
		}
	}

	public enum ChildAction: Sendable, Equatable {
		case editPersona(PresentationAction<EditPersona.Action>)
	}

	public enum DelegateAction: Sendable, Equatable {
		case personaDeauthorized
		case personaChanged(Profile.Network.Persona.ID)
	}

	public enum InternalAction: Sendable, Equatable {
		case editablePersonaFetched(Profile.Network.Persona)
		case reloaded(State.Mode)
	}

	// MARK: - Reducer

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.ifLet(\.$editPersona, action: /Action.child .. ChildAction.editPersona) {
				EditPersona()
			}
			.ifLet(\.$confirmForgetAlert, action: /Action.view .. ViewAction.confirmForgetAlert)
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .editPersona(.presented(.delegate(.personaSaved(persona)))):
			guard persona.id == state.mode.id else { return .none }
			return .run { [mode = state.mode] send in
				let updated = try await reload(in: mode)
				await send(.internal(.reloaded(updated)))
				await send(.delegate(.personaChanged(persona.id)))
			} catch: { _, _ in
				// FIXME: Log/show error?
			}

		case .editPersona:
			return .none
		}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .accountTapped:
			return .none

		case .editPersonaTapped:
			switch state.mode {
			case let .general(persona):
				return .send(.internal(.editablePersonaFetched(persona)))

			case let .dApp(_, persona: persona):
				return .run { send in
					let persona = try await personasClient.getPersona(id: persona.id)
					await send(.internal(.editablePersonaFetched(persona)))
				} catch: { _, _ in
					// FIXME: Log/show error?
				}
			}

		case .editAccountSharingTapped:
			return .none

		case .deauthorizePersonaTapped:
			state.confirmForgetAlert = .confirmForget
			return .none

		case .confirmForgetAlert(.presented(.confirmTapped)):
			guard case let .dApp(dApp, persona: persona) = state.mode else {
				return .none
			}
			let (personaID, dAppID, networkID) = (persona.id, dApp.dAppDefinitionAddress, dApp.networkID)
			return .run { send in
				try await authorizedDappsClient.deauthorizePersonaFromDapp(personaID, dAppID, networkID)
				await send(.delegate(.personaDeauthorized))
			} catch: { error, _ in
				errorQueue.schedule(error)
			}

		case .confirmForgetAlert:
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .editablePersonaFetched(persona):
			switch state.mode {
			case .general:
				state.editPersona = .init(mode: .edit, persona: persona)
			case let .dApp(_, detailedPersona):
				let fieldIDs = (detailedPersona.sharedFields ?? []).ids
				state.editPersona = .init(mode: .dapp(requiredFieldIDs: Set(fieldIDs)), persona: persona)
			}

			return .none

		case let .reloaded(mode):
			state.mode = mode
			return .none
		}
	}

	private func reload(in mode: State.Mode) async throws -> State.Mode {
		switch mode {
		case let .dApp(dApp, persona: persona):
			let updatedDapp = try await authorizedDappsClient.getDetailedDapp(dApp.dAppDefinitionAddress)
			guard let updatedPersona = updatedDapp.detailedAuthorizedPersonas[id: persona.id] else {
				// FIXME: Throw some error?
				return mode
			}
			return .dApp(updatedDapp, persona: updatedPersona)
		case let .general(persona):
			let updatedPersona = try await personasClient.getPersona(id: persona.id)
			return .general(updatedPersona)
		}
	}
}

extension AlertState<PersonaDetails.ViewAction.ConfirmForgetAlert> {
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
