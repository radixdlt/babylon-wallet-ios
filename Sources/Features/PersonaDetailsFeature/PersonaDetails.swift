import AuthorizedDappsClient
import CreateAuthKeyFeature
import EngineKit
import EditPersonaFeature
import FeaturePrelude
import GatewayAPI

// MARK: - PersonaDetails
public struct PersonaDetails: Sendable, FeatureReducer {
	@Dependency(\.gatewayAPIClient) var gatewayAPIClient
	@Dependency(\.personasClient) var personasClient
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.authorizedDappsClient) var authorizedDappsClient

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
				self.displayName = dApp.displayName?.rawValue ?? L10n.DAppRequest.Metadata.unknownName
			}
		}

		@PresentationState
		public var destination: Destination.State? = nil

		var identityAddress: IdentityAddress {
			mode.id
		}

		#if DEBUG
		public var canCreateAuthKey: Bool
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
			self.canCreateAuthKey = !hasAuthenticationSigningKey
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
		case personaToCreateAuthKeyForFetched(Profile.Network.Persona)
		case dAppLoaded(Profile.Network.AuthorizedDappDetailed)
	}

	// MARK: - Destination

	public struct Destination: ReducerProtocol {
		public enum State: Hashable {
			case editPersona(EditPersona.State)
			case createAuthKey(CreateAuthKey.State)
			case dAppDetails(SimpleAuthDappDetails.State)

			case confirmForgetAlert(AlertState<Action.ConfirmForgetAlert>)
		}

		public enum Action: Equatable {
			case editPersona(EditPersona.Action)
			case createAuthKey(CreateAuthKey.Action)
			case dAppDetails(SimpleAuthDappDetails.Action)

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
			Scope(state: /State.createAuthKey, action: /Action.createAuthKey) {
				CreateAuthKey()
			}
			Scope(state: /State.dAppDetails, action: /Action.dAppDetails) {
				SimpleAuthDappDetails()
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

		case let .destination(.presented(.createAuthKey(.delegate(.done(wasSuccessful))))):
			#if DEBUG
			state.canCreateAuthKey = false
			#endif
			state.destination = nil
			return .none

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
			let identityAddress = state.identityAddress
			return .run { send in
				let persona = try await personasClient.getPersona(id: identityAddress)
				await send(.internal(.personaToCreateAuthKeyForFetched(persona)))
			} catch: { error, _ in
				loggerGlobal.error("Could not get persona with address: \(identityAddress), error: \(error)")
				errorQueue.schedule(error)
			}
			return .none
		#endif

		case let .accountTapped(address):
			return .none

		case let .dAppTapped(dAppID):
			return .run { send in
				let dApp = try await authorizedDappsClient.getDetailedDapp(dAppID)
				await send(.internal(.dAppLoaded(dApp)))
			} catch: { error, _ in
				loggerGlobal.error("Could not get dApp details \(dAppID), error: \(error)")
				errorQueue.schedule(error)
			}
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
		case let .personaToCreateAuthKeyForFetched(persona):
			state.destination = .createAuthKey(.init(entity: .persona(persona)))
			return .none

		case let .editablePersonaFetched(persona):
			switch state.mode {
			case .general:
				state.destination = .editPersona(.init(mode: .edit, persona: persona))
			case let .dApp(_, detailedPersona):
//				let fieldIDs = (detailedPersona.sharedFields ?? []).ids
//				state.destination = .editPersona(.init(mode: .dapp(requiredFieldIDs: Set(fieldIDs)), persona: persona))
				fatalError()
			}

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

		case let .dAppLoaded(dApp):
			state.destination = .dAppDetails(.init(dApp: dApp))
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

// MARK: - SimpleAuthDappDetails
// FIXME: Remove and make settings use stacks

public struct SimpleAuthDappDetails: Sendable, FeatureReducer {
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.gatewayAPIClient) var gatewayAPIClient
	@Dependency(\.openURL) var openURL
	@Dependency(\.authorizedDappsClient) var authorizedDappsClient
	@Dependency(\.cacheClient) var cacheClient

	public struct FailedToLoadMetadata: Error, Hashable {}

	public typealias Store = StoreOf<Self>

	// MARK: State

	public struct State: Sendable, Hashable {
		public var dApp: Profile.Network.AuthorizedDappDetailed

		@Loadable
		public var metadata: GatewayAPI.EntityMetadataCollection? = nil

		@Loadable
		public var resources: Resources? = nil

		@Loadable
		public var associatedDapps: [AssociatedDapp]? = nil

		public init(
			dApp: Profile.Network.AuthorizedDappDetailed,
			metadata: GatewayAPI.EntityMetadataCollection? = nil,
			resources: Resources? = nil,
			associatedDapps: [AssociatedDapp]? = nil
		) {
			self.dApp = dApp
			self.metadata = metadata
			self.resources = resources
			self.associatedDapps = associatedDapps
		}

		public struct Resources: Hashable, Sendable {
			public var fungible: [ResourceDetails]
			public var nonFungible: [ResourceDetails]

			// TODO: This should be consolidated with other types that represent resources
			public struct ResourceDetails: Identifiable, Hashable, Sendable {
				public var id: ResourceAddress { address }

				public let address: ResourceAddress
				public let fungibility: Fungibility
				public let name: String
				public let symbol: String?
				public let description: String?
				public let iconURL: URL?

				public enum Fungibility: Hashable, Sendable {
					case fungible
					case nonFungible
				}
			}
		}

		// TODO: This should be consolidated with other types that represent resources
		public struct AssociatedDapp: Identifiable, Hashable, Sendable {
			public var id: DappDefinitionAddress { address }

			public let address: DappDefinitionAddress
			public let name: String
			public let iconURL: URL?
		}
	}

	// MARK: Action

	public enum ViewAction: Sendable, Equatable {
		case appeared
		case openURLTapped(URL)
	}

	public enum InternalAction: Sendable, Equatable {
		case metadataLoaded(Loadable<GatewayAPI.EntityMetadataCollection>)
		case resourcesLoaded(Loadable<State.Resources>)
		case associatedDappsLoaded(Loadable<[State.AssociatedDapp]>)
	}

	// MARK: - Destination

	// MARK: Reducer

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			state.$metadata = .loading
			state.$resources = .loading
			let dAppID = state.dApp.dAppDefinitionAddress
			return .task {
				let result = await TaskResult {
					try await cacheClient.withCaching(
						cacheEntry: .dAppMetadata(dAppID.address),
						request: {
							try await gatewayAPIClient.getEntityMetadata(dAppID.address)
						}
					)
				}
				return .internal(.metadataLoaded(.init(result: result)))
			}

		case let .openURLTapped(url):
			return .fireAndForget {
				await openURL(url)
			}
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .metadataLoaded(metadata):
			state.$metadata = metadata

			let dAppDefinitionAddress = state.dApp.dAppDefinitionAddress
			return .run { send in
				let resources = await metadata.flatMap { await loadResources(metadata: $0, validated: dAppDefinitionAddress) }
				await send(.internal(.resourcesLoaded(resources)))

				let associatedDapps = await metadata.flatMap { await loadDapps(metadata: $0, validated: dAppDefinitionAddress) }
				await send(.internal(.associatedDappsLoaded(associatedDapps)))
			}

		case let .resourcesLoaded(resources):
			state.$resources = resources
			return .none

		case let .associatedDappsLoaded(dApps):
			state.$associatedDapps = dApps
			return .none
		}
	}

	/// Loads any fungible and non-fungible resources associated with the dApp
	private func loadResources(
		metadata: GatewayAPI.EntityMetadataCollection,
		validated dappDefinitionAddress: DappDefinitionAddress
	) async -> Loadable<SimpleAuthDappDetails.State.Resources> {
		guard let claimedEntities = metadata.claimedEntities, !claimedEntities.isEmpty else {
			return .idle
		}

		let result = await TaskResult {
			let allResourceItems = try await gatewayAPIClient.fetchResourceDetails(claimedEntities)
				.items
				// FIXME: Uncomment this when when we can rely on dApps conforming to the standards
				// .filter { $0.metadata.dappDefinition == dAppDefinitionAddress.address }
				.compactMap {
					try $0.resourceDetails()
				}

			return State.Resources(fungible: allResourceItems.filter { $0.fungibility == .fungible },
			                       nonFungible: allResourceItems.filter { $0.fungibility == .nonFungible })
		}

		return .init(result: result)
	}

	/// Loads any other dApps associated with the dApp
	private func loadDapps(
		metadata: GatewayAPI.EntityMetadataCollection,
		validated dappDefinitionAddress: DappDefinitionAddress
	) async -> Loadable<[State.AssociatedDapp]> {
		let dAppDefinitions = try? metadata.dappDefinitions?.compactMap(DappDefinitionAddress.init)
		guard let dAppDefinitions else { return .idle }

		let associatedDapps = await dAppDefinitions.parallelMap { dApp in
			try? await extractDappInfo(for: dApp, validating: dappDefinitionAddress)
		}
		.compactMap { $0 }

		guard !associatedDapps.isEmpty else { return .idle }

		return .success(associatedDapps)
	}

	/// Helper function that loads and extracts dApp info for a given dApp, validating that it points back to the dApp of this screen
	private func extractDappInfo(
		for dApp: DappDefinitionAddress,
		validating dAppDefinitionAddress: DappDefinitionAddress
	) async throws -> State.AssociatedDapp {
		let metadata = try await gatewayAPIClient.getEntityMetadata(dApp.address)
		// FIXME: Uncomment this when when we can rely on dApps conforming to the standards
		// .validating(dAppDefinitionAddress: dAppDefinitionAddress)
		guard let name = metadata.name else {
			throw GatewayAPI.EntityMetadataCollection.MetadataError.missingName
		}
		return .init(address: dApp, name: name, iconURL: metadata.iconURL)
	}
}

extension GatewayAPI.StateEntityDetailsResponseItem {
	func resourceDetails() throws -> SimpleAuthDappDetails.State.Resources.ResourceDetails? {
		guard let fungibility else { return nil }
		let address = try ResourceAddress(validatingAddress: address)
		return .init(address: address,
		             fungibility: fungibility,
		             name: metadata.name ?? L10n.AuthorizedDapps.DAppDetails.unknownTokenName,
		             symbol: metadata.symbol,
		             description: metadata.description,
		             iconURL: metadata.iconURL)
	}

	private var fungibility: SimpleAuthDappDetails.State.Resources.ResourceDetails.Fungibility? {
		guard let details else { return nil }
		switch details {
		case .fungibleResource:
			return .fungible
		case .nonFungibleResource:
			return .nonFungible
		case .fungibleVault, .nonFungibleVault, .package, .component:
			return nil
		}
	}
}
