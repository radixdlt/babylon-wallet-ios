import ComposableArchitecture
import SwiftUI

// MARK: - PersonaDetails
public struct PersonaDetails: Sendable, FeatureReducer {
	@Dependency(\.onLedgerEntitiesClient) var onLedgerEntitiesClient
	@Dependency(\.personasClient) var personasClient
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.authorizedDappsClient) var authorizedDappsClient
	@Dependency(\.overlayWindowClient) var overlayWindowClient

	public init() {}

	// MARK: - State

	public struct State: Sendable, Hashable {
		public var mode: Mode

		public enum Mode: Sendable, Hashable {
			case general(Profile.Network.Persona, dApps: IdentifiedArrayOf<DappInfo>)

			case dApp(
				Profile.Network.AuthorizedDappDetailed,
				persona: Profile.Network.AuthorizedPersonaDetailed
			)

			var id: Profile.Network.Persona.ID {
				switch self {
				case let .general(persona, _): persona.id
				case let .dApp(_, persona: persona): persona.id
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
				self.displayName = dApp.displayName?.rawValue ?? L10n.DAppRequest.Metadata.unknownName
			}
		}

		@PresentationState
		public var destination: Destination.State? = nil

		var identityAddress: IdentityAddress {
			mode.id
		}

		public init(_ mode: Mode) {
			self.mode = mode
		}
	}

	// MARK: - Action

	public enum ViewAction: Sendable, Equatable {
		case appeared
		case dAppTapped(Profile.Network.AuthorizedDapp.ID)
		case editPersonaTapped
		case editAccountSharingTapped
		case deauthorizePersonaTapped
		case hidePersonaTapped
	}

	public enum ChildAction: Sendable, Equatable {
		case destination(PresentationAction<Destination.Action>)
	}

	public enum DelegateAction: Sendable, Equatable {
		case personaDeauthorized
		case personaChanged(Profile.Network.Persona.ID)
		case personaHidden
	}

	public enum InternalAction: Sendable, Equatable {
		case editablePersonaFetched(Profile.Network.Persona)
		case reloaded(State.Mode)
		case dAppsUpdated(IdentifiedArrayOf<State.DappInfo>)
		case callDone(updateControlState: WritableKeyPath<State, ControlState>, changeTo: ControlState)
		case hideLoader(updateControlState: WritableKeyPath<State, ControlState>)
		case dAppLoaded(Profile.Network.AuthorizedDappDetailed)
	}

	// MARK: - Destination

	public struct Destination: Reducer {
		public enum State: Hashable {
			case editPersona(EditPersona.State)
			case dAppDetails(DappDetails.State)

			case confirmForgetAlert(AlertState<Action.ConfirmForgetAlert>)
			case confirmHideAlert(AlertState<Action.ConfirmHideAlert>)
		}

		public enum Action: Equatable {
			case editPersona(EditPersona.Action)
			case dAppDetails(DappDetails.Action)

			case confirmForgetAlert(ConfirmForgetAlert)
			case confirmHideAlert(ConfirmHideAlert)

			public enum ConfirmForgetAlert: Sendable, Equatable {
				case confirmTapped
				case cancelTapped
			}

			public enum ConfirmHideAlert: Sendable, Equatable {
				case confirmTapped
				case cancelTapped
			}
		}

		public var body: some ReducerOf<Self> {
			Scope(state: /State.editPersona, action: /Action.editPersona) {
				EditPersona()
			}
			Scope(state: /State.dAppDetails, action: /Action.dAppDetails) {
				DappDetails()
			}
		}
	}

	// MARK: - Reducer

	public var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(\.$destination, action: /Action.child .. ChildAction.destination) {
				Destination()
			}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case let .destination(.presented(presentedAction)):
			switch presentedAction {
			case let .editPersona(.delegate(.personaSaved(persona))):
				guard persona.id == state.mode.id else { return .none }
				return reloadEffect(mode: state.mode, notifyDelegate: true)

			case .dAppDetails(.delegate(.dAppForgotten)):
				state.destination = nil
				return reloadEffect(mode: state.mode, notifyDelegate: false)

			case .confirmForgetAlert(.confirmTapped):
				guard case let .dApp(dApp, persona: persona) = state.mode else { return .none }
				let (personaID, dAppID, networkID) = (persona.id, dApp.dAppDefinitionAddress, dApp.networkID)
				return .run { send in
					try await authorizedDappsClient.deauthorizePersonaFromDapp(personaID, dAppID, networkID)
					await send(.delegate(.personaDeauthorized))
				} catch: { error, _ in
					loggerGlobal.error("Failed to deauthorize persona \(personaID) from dApp \(dAppID), error: \(error)")
					errorQueue.schedule(error)
				}

			case .confirmHideAlert(.confirmTapped):
				guard case let .general(persona, _) = state.mode else {
					return .none
				}
				return .run { send in
					do {
						var persona = persona
						persona.flags.insert(.deletedByUser)
						try await personasClient.updatePersona(persona)
						overlayWindowClient.scheduleHUD(.personaHidden)
						await send(.delegate(.personaHidden))
					} catch {
						errorQueue.schedule(error)
					}
				}

			default:
				return .none
			}
		case .destination:
			return .none
		}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .appeared:
			guard case let .general(_, dApps) = state.mode else { return .none }
			return .run { send in
				await send(.internal(.dAppsUpdated(addingDappMetadata(to: dApps))))
			}

		case let .dAppTapped(dAppID):
			return .run { send in
				let dApp = try await authorizedDappsClient.getDetailedDapp(dAppID)
				await send(.internal(.dAppLoaded(dApp)))
			} catch: { error, _ in
				loggerGlobal.error("Could not get dApp details \(dAppID), error: \(error)")
				errorQueue.schedule(error)
			}

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

		case .hidePersonaTapped:
			guard case .general = state.mode else {
				assertionFailure("Can hide persona only")
				return .none
			}

			state.destination = .confirmHideAlert(.confirmHide)
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .editablePersonaFetched(persona):
			switch state.mode {
			case .general:
				state.destination = .editPersona(.init(mode: .edit, persona: persona))
			case let .dApp(_, detailedPersona):
				// TODO: This should be tested
				let required = Set(detailedPersona.sharedPersonaData.entries.map(\.value.discriminator))
				state.destination = .editPersona(.init(mode: .dapp(requiredEntries: required), persona: persona))
			}

			return .none

		case let .dAppsUpdated(updatedDapps):
			guard case .general(let persona, var dApps) = state.mode else { return .none }
			for updatedDapp in updatedDapps where dApps.ids.contains(updatedDapp.id) {
				dApps[id: updatedDapp.id] = updatedDapp
			}

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

		case let .dAppLoaded(dApp):
			state.destination = .dAppDetails(.init(dApp: dApp, context: .personaDetails))
			return .none
		}
	}

	private func reloadEffect(mode: State.Mode, notifyDelegate: Bool) -> Effect<Action> {
		.run { send in
			let updated = try await reload(in: mode)
			await send(.internal(.reloaded(updated)))
			if notifyDelegate {
				await send(.delegate(.personaChanged(mode.id)))
			}
		} catch: { error, _ in
			loggerGlobal.error("Failed to reload, error: \(error)")
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
				let metadata = try await onLedgerEntitiesClient.getDappMetadata(dApp.id)
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
	) -> Effect<Action> {
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
			TextState(L10n.AuthorizedDapps.RemoveAuthorizationAlert.title)
		} actions: {
			ButtonState(role: .destructive, action: .confirmTapped) {
				TextState(L10n.AuthorizedDapps.RemoveAuthorizationAlert.confirm)
			}
			ButtonState(role: .cancel, action: .cancelTapped) {
				TextState(L10n.Common.cancel)
			}
		} message: {
			TextState(L10n.AuthorizedDapps.RemoveAuthorizationAlert.message)
		}
	}
}

extension AlertState<PersonaDetails.Destination.Action.ConfirmHideAlert> {
	static var confirmHide: AlertState {
		AlertState(
			title: .init(L10n.AuthorizedDapps.PersonaDetails.hideThisPersona),
			message: .init(L10n.AuthorizedDapps.PersonaDetails.hidePersonaConfirmation),
			buttons: [
				.cancel(.init(L10n.Common.cancel), action: .send(.cancelTapped)),
				.destructive(.init(L10n.AccountSettings.hideAccount), action: .send(.confirmTapped)),
			]
		)
	}
}
