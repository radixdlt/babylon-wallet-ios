import AuthorizedDappsClient
import EditPersonaFeature
import FeaturePrelude
import GatewayAPI

// MARK: - PersonaDetails
public struct PersonaDetails: Sendable, FeatureReducer {
	@Dependency(\.gatewayAPIClient) var gatewayAPIClient
	@Dependency(\.personasClient) var personasClient
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.authorizedDappsClient) var authorizedDappsClient

	public typealias Store = StoreOf<Self>

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
		public var confirmForgetAlert: AlertState<ViewAction.ConfirmForgetAlert>? = nil

		@PresentationState
		public var editPersona: EditPersona.State? = nil

		public init(_ mode: Mode) {
			self.mode = mode
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
		case dAppsUpdated(IdentifiedArrayOf<State.DappInfo>)
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
			} catch: { error, _ in
				loggerGlobal.error("Failed to reload, error: \(error)")
			}

		case .editPersona:
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
				loggerGlobal.error("Failed to deauthorize persona \(personaID) from dApp \(dAppID), error: \(error)")
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

		case let .dAppsUpdated(dApps):
			guard case let .general(persona, _) = state.mode else { return .none }
			state.mode = .general(persona, dApps: dApps)
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
				print("Loading metadata for \(dApp.id)")

				let metadata = try await gatewayAPIClient.getDappDefinition(dApp.id.address)
				dApps[id: dApp.id]?.thumbnail = metadata.iconURL
				print("Loaded metadata for \(metadata.name)")
			} catch {
				loggerGlobal.error("Failed to load dApp metadata, error: \(error)")
			}
		}
		return dApps
	}

	enum ReloadError: Error {
		case personaNotPresentInDapp(Profile.Network.Persona.ID, Profile.Network.AuthorizedDapp.ID)
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
