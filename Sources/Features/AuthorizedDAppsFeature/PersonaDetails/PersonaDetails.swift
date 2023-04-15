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
		public let dAppName: String
		public let dAppID: Profile.Network.AuthorizedDapp.ID
		public let networkID: NetworkID
		public let persona: Profile.Network.AuthorizedPersonaDetailed

		public var metadata: PersonaMetadata.State

		@PresentationState
		public var confirmForgetAlert: AlertState<ViewAction.ConfirmForgetAlert>? = nil

		public init(
			dAppName: String,
			dAppID: Profile.Network.AuthorizedDapp.ID,
			networkID: NetworkID,
			persona: Profile.Network.AuthorizedPersonaDetailed
		) {
			self.dAppName = dAppName
			self.dAppID = dAppID
			self.networkID = networkID
			self.persona = persona

			self.metadata = .init(persona: persona,
			                      dAppName: dAppName,
			                      requiredFields: [.givenName])
		}
	}

	// MARK: - Action

	public enum ViewAction: Sendable, Equatable {
		case accountTapped(AccountAddress)
		case editAccountSharingTapped
		case deauthorizePersonaTapped
		case confirmForgetAlert(PresentationAction<ConfirmForgetAlert>)

		public enum ConfirmForgetAlert: Sendable, Equatable {
			case confirmTapped
			case cancelTapped
		}
	}

	public enum ChildAction: Sendable, Equatable {
		case metadata(PersonaMetadata.Action)
	}

	public enum DelegateAction: Sendable, Equatable {
		case personaDeauthorized
	}

	// MARK: - Reducer

	public var body: some ReducerProtocolOf<Self> {
		Scope(state: \.metadata, action: /Action.child .. ChildAction.metadata) {
			PersonaMetadata()
		}
		Reduce(core)
			.ifLet(\.$confirmForgetAlert, action: /Action.view .. ViewAction.confirmForgetAlert)
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .accountTapped:
			return .none

		case .editAccountSharingTapped:
			return .none

		case .deauthorizePersonaTapped:
			state.confirmForgetAlert = .confirmForget
			return .none

		case .confirmForgetAlert(.presented(.confirmTapped)):
			let (personaID, dAppID, networkID) = (state.persona.id, state.dAppID, state.networkID)
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

// MARK: - PersonaMetadata
public struct PersonaMetadata: Sendable, FeatureReducer {
	@Dependency(\.personasClient) var personasClient
	@Dependency(\.errorQueue) var errorQueue

	public typealias Store = StoreOf<Self>

	public init() {}

	// MARK: - State

	public struct State: Sendable, Hashable {
		public let id: Profile.Network.Persona.ID
		public var thumbnail: URL?
		public var name: String
		public var fields: IdentifiedArrayOf<Profile.Network.Persona.Field>
		public let mode: Mode

		public enum Mode: Sendable, Hashable {
			case general
			case dApp(name: String, requiredFields: Set<Profile.Network.Persona.Field.ID>)
		}

		@PresentationState
		public var editPersona: EditPersona.State? = nil

		public init(
			persona: Profile.Network.Persona
		) {
			self.id = persona.id
			self.thumbnail = nil
			self.name = persona.displayName.rawValue
			self.fields = persona.fields
			self.mode = .general
		}

		public init(
			persona: Profile.Network.AuthorizedPersonaDetailed,
			dAppName: String,
			requiredFields: Set<Profile.Network.Persona.Field.ID>
		) {
			self.id = persona.id
			self.thumbnail = nil
			self.name = persona.displayName.rawValue
			self.fields = persona.sharedFields ?? []
			self.mode = .dApp(name: dAppName, requiredFields: requiredFields)
		}
	}

	// MARK: - Action

	public enum ViewAction: Sendable, Equatable {
		case editPersonaTapped
	}

	public enum InternalAction: Sendable, Equatable {
		case editablePersonaFetched(Profile.Network.Persona)
	}

	public enum ChildAction: Sendable, Equatable {
		case editPersona(PresentationAction<EditPersona.Action>)
	}

	public enum DelegateAction: Sendable, Equatable {
		case personaChanged(Profile.Network.Persona)
	}

	// MARK: - Reducer

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.ifLet(\.$editPersona, action: /Action.child .. ChildAction.editPersona) {
				EditPersona()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .editPersonaTapped:
			return .run { [id = state.id] send in
				guard let persona = try? await personasClient.getPersonas()[id: id] else {
					// FIXME: Log/show error?
					return
				}
				await send(.internal(.editablePersonaFetched(persona)))
			}
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .editPersona(.presented(.delegate(.personaSaved(persona)))):
			state.fields = persona.fields
			state.name = persona.displayName.rawValue

			return .send(.delegate(.personaChanged(persona)))
		case .editPersona:
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .editablePersonaFetched(persona):
			switch state.mode {
			case .general:
				state.editPersona = .init(mode: .edit, persona: persona)
			case let .dApp(_, fields):
				state.editPersona = .init(mode: .dapp(requiredFieldIDs: fields), persona: persona)
			}

			return .none
		}
	}
}
