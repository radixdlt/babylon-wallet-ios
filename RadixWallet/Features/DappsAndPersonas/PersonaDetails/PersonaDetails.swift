import ComposableArchitecture
import Sargon
import SwiftUI

// MARK: - PersonaDetails
struct PersonaDetails: Sendable, FeatureReducer {
	@Dependency(\.onLedgerEntitiesClient) var onLedgerEntitiesClient
	@Dependency(\.personasClient) var personasClient
	@Dependency(\.entitiesVisibilityClient) var entitiesVisibilityClient
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.authorizedDappsClient) var authorizedDappsClient
	@Dependency(\.overlayWindowClient) var overlayWindowClient
	@Dependency(\.factorSourcesClient) var factorSourcesClient

	init() {}

	// MARK: - State

	struct State: Sendable, Hashable {
		enum SecurityState: Hashable {
			case unsecurified(FactorSourcesList.Row)
			case securified
		}

		var mode: Mode
		var securityState: SecurityState?

		enum Mode: Sendable, Hashable {
			case general(dApps: IdentifiedArrayOf<DappInfo>)

			case dApp(
				AuthorizedDappDetailed,
				authorizedPersonaData: AuthorizedPersonaDetailed
			)
		}

		struct DappInfo: Sendable, Hashable, Identifiable {
			let id: AuthorizedDapp.ID
			var thumbnail: URL?
			let displayName: String

			init(dApp: AuthorizedDapp) {
				self.id = dApp.id
				self.thumbnail = nil
				self.displayName = dApp.displayName ?? L10n.DAppRequest.Metadata.unknownName
			}
		}

		@PresentationState
		var destination: Destination.State? = nil

		var persona: Persona
		var identityAddress: IdentityAddress {
			persona.id
		}

		init(persona: Persona, _ mode: Mode) {
			self.persona = persona
			self.mode = mode
		}
	}

	// MARK: - Action

	enum ViewAction: Sendable, Equatable {
		case appeared
		case dAppTapped(AuthorizedDapp.ID)
		case editPersonaTapped
		case editAccountSharingTapped
		case deauthorizePersonaTapped
		case hidePersonaTapped
		case factorSourceCardTapped(FactorSourcesList.Row)
		case factorSourceMessageTapped(FactorSourcesList.Row)
		case applyShieldButtonTapped
		case viewShieldDetailsRowTapped
	}

	enum DelegateAction: Sendable, Equatable {
		case personaDeauthorized
		case personaChanged(Persona.ID)
		case personaHidden
	}

	enum InternalAction: Sendable, Equatable {
		case reloaded(Persona, State.Mode)
		case dAppsUpdated(IdentifiedArrayOf<State.DappInfo>)
		case callDone(updateControlState: WritableKeyPath<State, ControlState>, changeTo: ControlState)
		case hideLoader(updateControlState: WritableKeyPath<State, ControlState>)
		case dAppLoaded(AuthorizedDappDetailed)
		case securityStateDetermined(State.SecurityState)
		case reloadPersona
	}

	// MARK: - Destination

	struct Destination: DestinationReducer {
		@CasePathable
		enum State: Sendable, Hashable {
			case editPersona(EditPersona.State)
			case dAppDetails(DappDetails.State)
			case factorSourceDetail(FactorSourceDetail.State)
			case displayMnemonic(DisplayMnemonic.State)
			case enterMnemonic(ImportMnemonicForFactorSource.State)
			case selectShield(SelectShield.State)
			case applyShield(ApplyShield.Coordinator.State)
			case shieldDetails(EntityShieldDetails.State)

			case confirmForgetAlert(AlertState<Action.ConfirmForgetAlert>)
			case confirmHideAlert(AlertState<Action.ConfirmHideAlert>)
		}

		@CasePathable
		enum Action: Sendable, Equatable {
			case editPersona(EditPersona.Action)
			case dAppDetails(DappDetails.Action)
			case factorSourceDetail(FactorSourceDetail.Action)
			case displayMnemonic(DisplayMnemonic.Action)
			case enterMnemonic(ImportMnemonicForFactorSource.Action)
			case selectShield(SelectShield.Action)
			case applyShield(ApplyShield.Coordinator.Action)
			case shieldDetails(EntityShieldDetails.Action)

			case confirmForgetAlert(ConfirmForgetAlert)
			case confirmHideAlert(ConfirmHideAlert)

			@CasePathable
			enum ConfirmForgetAlert: Sendable, Equatable {
				case confirmTapped
				case cancelTapped
			}

			enum ConfirmHideAlert: Sendable, Equatable {
				case confirmTapped
				case cancelTapped
			}
		}

		var body: some ReducerOf<Self> {
			Scope(state: \.editPersona, action: \.editPersona) {
				EditPersona()
			}
			Scope(state: \.dAppDetails, action: \.dAppDetails) {
				DappDetails()
			}
			Scope(state: \.factorSourceDetail, action: \.factorSourceDetail) {
				FactorSourceDetail()
			}
			Scope(state: \.displayMnemonic, action: \.displayMnemonic) {
				DisplayMnemonic()
			}
			Scope(state: \.enterMnemonic, action: \.enterMnemonic) {
				ImportMnemonicForFactorSource()
			}
			Scope(state: \.selectShield, action: \.selectShield) {
				SelectShield()
			}
			Scope(state: \.applyShield, action: \.applyShield) {
				ApplyShield.Coordinator()
			}
			Scope(state: \.shieldDetails, action: \.shieldDetails) {
				EntityShieldDetails()
			}
		}
	}

	// MARK: - Reducer

	var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(destinationPath, action: \.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .appeared:
			let loadSecStateffect = loadSecState(state: state)
			guard case let .general(dApps) = state.mode else { return loadSecStateffect }
			return loadSecStateffect.merge(with: .run { send in
				await send(.internal(.dAppsUpdated(addingDappMetadata(to: dApps))))
			})

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
			case .general:
				state.destination = .editPersona(.init(mode: .edit(state.persona)))
			case let .dApp(_, detailedPersona):
				let required = Set(detailedPersona.sharedPersonaData.entries.map(\.value.discriminator))
				state.destination = .editPersona(.init(mode: .dapp(persona: state.persona, requiredEntries: required)))
			}
			return .none

		case .editAccountSharingTapped:
			return .none

		case .deauthorizePersonaTapped:
			state.destination = .confirmForgetAlert(.confirmForget)
			return .none

		case .hidePersonaTapped:
			guard case .general = state.mode else {
				return .none
			}

			state.destination = .confirmHideAlert(.confirmHide)
			return .none

		case let .factorSourceCardTapped(row):
			state.destination = .factorSourceDetail(.init(integrity: row.integrity))
			return .none

		case let .factorSourceMessageTapped(row):
			switch row.status {
			case .seedPhraseWrittenDown, .notBackedUp:
				return .none

			case .seedPhraseNotRecoverable:
				return exportMnemonic(integrity: row.integrity) {
					state.destination = .displayMnemonic(.init(mnemonic: $0.mnemonicWithPassphrase.mnemonic, factorSourceID: $0.factorSourceID))
				}

			case .lostFactorSource:
				state.destination = .enterMnemonic(.init(
					deviceFactorSource: row.integrity.factorSource.asDevice!,
					profileToCheck: .current
				))
				return .none

			case .none:
				return .none
			}

		case .applyShieldButtonTapped:
			state.destination = .selectShield(.init())
			return .none

		case .viewShieldDetailsRowTapped:
			state.destination = .shieldDetails(.init(entityAddress: .identity(state.persona.address)))
			return .none
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .dAppsUpdated(updatedDapps):
			guard case var .general(dApps) = state.mode else { return .none }
			for updatedDapp in updatedDapps where dApps.ids.contains(updatedDapp.id) {
				dApps[id: updatedDapp.id] = updatedDapp
			}

			state.mode = .general(dApps: dApps)
			return .none

		case let .reloaded(persona, mode):
			state.persona = persona
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

		case let .securityStateDetermined(securityState):
			state.securityState = securityState
			return .none

		case .reloadPersona:
			return reloadEffect(state: state, notifyDelegate: false)
		}
	}

	func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case .editPersona(.delegate(.personaSaved)):
			state.destination = nil
			return reloadEffect(state: state, notifyDelegate: true)

		case .dAppDetails(.delegate(.dAppForgotten)):
			state.destination = nil
			return reloadEffect(state: state, notifyDelegate: false)

		case .confirmForgetAlert(.confirmTapped):
			guard case let .dApp(dApp, authorizedPersonaData) = state.mode else { return .none }
			let (personaID, dAppID, networkID) = (authorizedPersonaData.id, dApp.dAppDefinitionAddress, dApp.networkId)
			return .run { send in
				try await authorizedDappsClient.deauthorizePersonaFromDapp(personaID, dAppID, networkID)
				await send(.delegate(.personaDeauthorized))
			} catch: { error, _ in
				loggerGlobal.error("Failed to deauthorize persona \(personaID) from dApp \(dAppID), error: \(error)")
				errorQueue.schedule(error)
			}

		case .confirmHideAlert(.confirmTapped):
			guard case .general = state.mode else {
				return .none
			}
			return .run { [id = state.persona.id] send in
				try await entitiesVisibilityClient.hidePersona(id)
				overlayWindowClient.scheduleHUD(.personaHidden)
				await send(.delegate(.personaHidden))
			} catch: { error, _ in
				errorQueue.schedule(error)
			}

		case .enterMnemonic(.delegate(.closed)):
			state.destination = nil
			return .none

		case .enterMnemonic(.delegate(.imported)):
			state.destination = nil
			return loadSecState(state: state)

		case .displayMnemonic(.delegate(.backedUp)):
			state.destination = nil
			return loadSecState(state: state)

		case let .selectShield(.delegate(.confirmed(shield))):
			state.destination = .applyShield(.init(securityStructure: shield, selectedPersonas: [state.persona.address], root: .completion))
			return .none

		case .applyShield(.delegate(.finished)):
			state.destination = nil
			return .run { [address = state.persona.address] send in
				_ = try await personasClient.personaUpdates(address).dropFirst().first()
				await send(.internal(.reloadPersona))
			}

		default:
			return .none
		}
	}

	private func reloadEffect(state: State, notifyDelegate: Bool) -> Effect<Action> {
		.run { [id = state.persona.id, mode = state.mode] send in
			let updatedPersona = try await personasClient.getPersona(id: id)
			let updatedMode = try await reload(personaID: id, mode: mode)
			await send(.internal(.reloaded(updatedPersona, updatedMode)))
			if notifyDelegate {
				await send(.delegate(.personaChanged(id)))
			}
		} catch: { error, _ in
			loggerGlobal.error("Failed to reload, error: \(error)")
		}
	}

	private func reload(personaID: Persona.ID, mode: State.Mode) async throws -> State.Mode {
		switch mode {
		case let .dApp(dApp, auhtorizedPersonaData):
			let updatedDapp = try await authorizedDappsClient.getDetailedDapp(dApp.dAppDefinitionAddress)
			let identifiedDetailedAuthorizedPersonas = updatedDapp.detailedAuthorizedPersonas.asIdentified()
			guard let updatedPersona = identifiedDetailedAuthorizedPersonas[id: auhtorizedPersonaData.id] else {
				throw ReloadError.personaNotPresentInDapp(auhtorizedPersonaData.id, updatedDapp.dAppDefinitionAddress)
			}
			return .dApp(updatedDapp, authorizedPersonaData: updatedPersona)
		case .general:
			let dApps = try await authorizedDappsClient.getDappsAuthorizedByPersona(personaID)
				.map(State.DappInfo.init)

			return await .general(dApps: addingDappMetadata(to: dApps.asIdentified()))
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
		return .run { [address = state.identityAddress] send in
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
		case personaNotPresentInDapp(Persona.ID, AuthorizedDapp.ID)
	}

	private func loadSecState(state: State) -> Effect<Action> {
		switch state.persona.securityState {
		case let .unsecured(control):
			.run { send in
				if let fs = try? await factorSourcesClient.getFactorSource(of: control.transactionSigning.factorInstance) {
					let integrity = try await SargonOS.shared.factorSourceIntegrity(factorSource: fs)
					let factorSourceRowState = FactorSourcesList.Row(
						integrity: integrity,
						linkedEntities: .init(accounts: [], personas: [], hasHiddenEntities: false),
						status: .init(integrity: integrity),
						selectability: .selectable
					)
					await send(.internal(.securityStateDetermined(.unsecurified(factorSourceRowState))))
				}
			}
		case .securified:
			.send(.internal(.securityStateDetermined(.securified)))
		}
	}
}

private extension OverlayWindowClient.Item.HUD {
	static let personaHidden = Self(text: L10n.AuthorizedDapps.PersonaDetails.personaHidden)
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
				.default(.init(L10n.Common.continue), action: .send(.confirmTapped)),
				.cancel(.init(L10n.Common.cancel), action: .send(.cancelTapped)),
			]
		)
	}
}
