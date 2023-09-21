import AssetsFeature
import AuthorizedDappsClient
import CacheClient
import EditPersonaFeature
import EngineKit
import FeaturePrelude
import GatewayAPI
import OnLedgerEntitiesClient

// MARK: - DappDetails
public struct DappDetails: Sendable, FeatureReducer {
	@Dependency(\.dismiss) var dismiss
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.gatewayAPIClient) var gatewayAPIClient
	@Dependency(\.openURL) var openURL
	@Dependency(\.authorizedDappsClient) var authorizedDappsClient
	@Dependency(\.cacheClient) var cacheClient
	@Dependency(\.continuousClock) var clock
	@Dependency(\.onLedgerEntitiesClient) var onLedgerEntitiesClient

	public struct FailedToLoadMetadata: Error, Hashable {}

	public typealias Store = StoreOf<Self>

	// MARK: State

	public struct State: Sendable, Hashable {
		public enum Context: Sendable, Hashable {
			case general
			case settings(SettingsContext)

			public enum SettingsContext: Sendable, Hashable {
				case personaDetails
				case authorizedDapps
			}
		}

		public let context: Context

		public let dAppDefinitionAddress: DappDefinitionAddress

		// This will only be non-nil if the dApp is in fact authorized
		public var authorizedDapp: Profile.Network.AuthorizedDappDetailed?

		public var personaList: PersonaList.State

		@Loadable
		public var metadata: GatewayAPI.EntityMetadataCollection? = nil

		@Loadable
		public var resources: Resources? = nil

		@Loadable
		public var associatedDapps: [OnLedgerEntity.AssociatedDapp]? = nil

		@PresentationState
		public var destination: Destination.State? = nil

		// Authorized dApp
		public init(
			dApp: Profile.Network.AuthorizedDappDetailed,
			context: Context.SettingsContext,
			metadata: GatewayAPI.EntityMetadataCollection? = nil,
			resources: Resources? = nil,
			associatedDapps: [OnLedgerEntity.AssociatedDapp]? = nil,
			destination: Destination.State? = nil
		) {
			self.context = .settings(context)
			self.dAppDefinitionAddress = dApp.dAppDefinitionAddress
			self.authorizedDapp = dApp
			self.personaList = .init(dApp: dApp)
			self.metadata = metadata
			self.resources = resources
			self.associatedDapps = associatedDapps
			self.destination = destination
		}

		// General
		public init(
			dAppDefinitionAddress: DappDefinitionAddress,
			metadata: GatewayAPI.EntityMetadataCollection? = nil,
			resources: Resources? = nil,
			associatedDapps: [OnLedgerEntity.AssociatedDapp]? = nil,
			destination: Destination.State? = nil
		) {
			self.context = .general
			self.dAppDefinitionAddress = dAppDefinitionAddress
			self.authorizedDapp = nil
			self.personaList = .init()
			self.metadata = metadata
			self.resources = resources
			self.associatedDapps = associatedDapps
			self.destination = destination
		}

		public struct Resources: Hashable, Sendable {
			public var fungible: IdentifiedArrayOf<OnLedgerEntity.Resource>
			public var nonFungible: IdentifiedArrayOf<OnLedgerEntity.Resource>
		}
	}

	// MARK: Action

	public enum ViewAction: Sendable, Equatable {
		case appeared
		case openURLTapped(URL)
		case fungibleTapped(ResourceAddress)
		case nonFungibleTapped(ResourceAddress)
		case dAppTapped(DappDefinitionAddress)
		case forgetThisDappTapped
	}

	public enum DelegateAction: Sendable, Equatable {
		case dAppForgotten
	}

	public enum InternalAction: Sendable, Equatable {
		case metadataLoaded(Loadable<GatewayAPI.EntityMetadataCollection>)
		case resourcesLoaded(Loadable<State.Resources>)
		case associatedDappsLoaded(Loadable<[OnLedgerEntity.AssociatedDapp]>)
		case dAppUpdated(Profile.Network.AuthorizedDappDetailed)
	}

	public enum ChildAction: Sendable, Equatable {
		case personas(PersonaList.Action)
		case destination(PresentationAction<Destination.Action>)
	}

	// MARK: - Destination

	public struct Destination: Reducer {
		public enum State: Equatable, Hashable {
			case personaDetails(PersonaDetails.State)
			case fungibleDetails(FungibleTokenDetails.State)
			case nonFungibleDetails(NonFungibleTokenDetails.State)
			case dappDetails(DappDetails.State)
			case confirmDisconnectAlert(AlertState<Action.ConfirmDisconnectAlert>)
		}

		public enum Action: Equatable {
			case personaDetails(PersonaDetails.Action)
			case fungibleDetails(FungibleTokenDetails.Action)
			case nonFungibleDetails(NonFungibleTokenDetails.Action)
			case dappDetails(DappDetails.Action)
			case confirmDisconnectAlert(ConfirmDisconnectAlert)

			public enum ConfirmDisconnectAlert: Sendable, Equatable {
				case confirmTapped
				case cancelTapped
			}
		}

		public var body: some ReducerOf<Self> {
			Scope(state: /State.personaDetails, action: /Action.personaDetails) {
				PersonaDetails()
			}
			Scope(state: /State.fungibleDetails, action: /Action.fungibleDetails) {
				FungibleTokenDetails()
			}
			Scope(state: /State.nonFungibleDetails, action: /Action.nonFungibleDetails) {
				NonFungibleTokenDetails()
			}
		}
	}

	// MARK: Reducer

	struct MissingResource: LocalizedError {
		let address: ResourceAddress

		var errorDescription: String {
			"Missing resource: \(address)"
		}
	}

	public init() {}

	public var body: some ReducerOf<Self> {
		Scope(state: \.personaList, action: /Action.child .. ChildAction.personas) {
			PersonaList()
		}
		Reduce(core)
			.ifLet(\.$destination, action: /Action.child .. ChildAction.destination) {
				Destination()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .appeared:
			state.$metadata = .loading
			state.$resources = .loading
			let dAppID = state.dAppDefinitionAddress
			let checkForAuthorizedDapp = state.authorizedDapp == nil
			return .run { send in
				if checkForAuthorizedDapp, let authorizedDapp = try? await authorizedDappsClient.getDetailedDapp(dAppID) {
					await send(.internal(.dAppUpdated(authorizedDapp)))
				}

				let result = await TaskResult {
					try await cacheClient.withCaching(
						cacheEntry: .dAppMetadata(dAppID.address),
						request: {
							try await gatewayAPIClient.getEntityMetadata(dAppID.address, .dappMetadataKeys)
						}
					)
				}
				await send(.internal(.metadataLoaded(.init(result: result))))
			} catch: { error, _ in
				errorQueue.schedule(error)
			}

		case let .openURLTapped(url):
			return .run { _ in
				await openURL(url)
			}

		case let .fungibleTapped(address):
			guard let resource = state.resources?.fungible[id: address] else {
				errorQueue.schedule(MissingResource(address: address))
				return .none
			}

			// FIXME: Can a dApp be associated with XRD
			state.destination = .fungibleDetails(.init(resource: resource, isXRD: false))
			return .none

		case let .nonFungibleTapped(address):
			guard let resource = state.resources?.nonFungible[id: address] else {
				errorQueue.schedule(MissingResource(address: address))
				return .none
			}

			state.destination = .nonFungibleDetails(.init(resource: resource))
			return .none

		case let .dAppTapped(address):
			state.destination = .dappDetails(.init(dAppDefinitionAddress: address))
			return .none

		case .forgetThisDappTapped:
			state.destination = .confirmDisconnectAlert(.confirmDisconnect)
			return .none
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case let .destination(.presented(destinationAction)):
			switch destinationAction {
			case .personaDetails(.delegate(.personaDeauthorized)):
				let dAppID = state.dAppDefinitionAddress
				return update(dAppID: dAppID, dismissPersonaDetails: true)

			case .personaDetails(.delegate(.personaChanged)):
				let dAppID = state.dAppDefinitionAddress
				return update(dAppID: dAppID, dismissPersonaDetails: false)

			case .confirmDisconnectAlert(.confirmTapped):
				assert(state.authorizedDapp != nil, "Can only disconnect a dApp that has been authorized")
				guard let networkID = state.authorizedDapp?.networkID else { return .none }
				return disconnectDappEffect(dAppID: state.dAppDefinitionAddress, networkID: networkID)

			default:
				return .none
			}

		case .destination:
			return .none

		case let .personas(.delegate(.openDetails(persona))):
			guard let dApp = state.authorizedDapp, let detailedPersona = dApp.detailedAuthorizedPersonas[id: persona.id] else { return .none }
			let personaDetailsState = PersonaDetails.State(.dApp(dApp, persona: detailedPersona))
			state.destination = .personaDetails(personaDetailsState)
			return .none

		case .personas:
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .metadataLoaded(metadata):
			state.$metadata = metadata

			let dAppDefinitionAddress = state.dAppDefinitionAddress
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

		case let .dAppUpdated(dApp):
			assert(dApp.dAppDefinitionAddress == state.dAppDefinitionAddress, "dAppUpdated called with wrong dApp")
			guard !dApp.detailedAuthorizedPersonas.isEmpty else {
				// FIXME: Without this delay, the screen is never dismissed
				return disconnectDappEffect(dAppID: dApp.dAppDefinitionAddress, networkID: dApp.networkID, delay: .milliseconds(500))
			}
			state.authorizedDapp = dApp
			state.personaList = .init(dApp: dApp)

			return .none
		}
	}

	/// Loads any fungible and non-fungible resources associated with the dApp
	private func loadResources(
		metadata: GatewayAPI.EntityMetadataCollection,
		validated dAppDefinitionAddress: DappDefinitionAddress
	) async -> Loadable<State.Resources> {
		let resources = metadata.claimedEntities?.compactMap { try? ResourceAddress(validatingAddress: $0) } ?? []
		guard !resources.isEmpty else { return .idle }

		let result = await TaskResult {
			let items = try await onLedgerEntitiesClient.getResources(resources)
				.filter { $0.dappDefinitions?.contains(dAppDefinitionAddress) == true }
			let fungible: IdentifiedArray = .init(items.filter { $0.fungibility == .fungible }) { $1 }
			let nonFungible: IdentifiedArray = .init(items.filter { $0.fungibility == .nonFungible }) { $1 }

			return State.Resources(fungible: fungible, nonFungible: nonFungible)
		}

		return .init(result: result)
	}

	/// Loads any other dApps associated with the dApp
	private func loadDapps(
		metadata: GatewayAPI.EntityMetadataCollection,
		validated dappDefinitionAddress: DappDefinitionAddress
	) async -> Loadable<[OnLedgerEntity.AssociatedDapp]> {
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
	) async throws -> OnLedgerEntity.AssociatedDapp {
		let metadata = try await gatewayAPIClient.getDappMetadata(dApp, validatingDappDefinitionAddress: dAppDefinitionAddress)
		guard let name = metadata.name else {
			throw GatewayAPI.EntityMetadataCollection.MetadataError.missingName
		}
		return .init(address: dApp, name: name, iconURL: metadata.iconURL)
	}

	private func update(dAppID: DappDefinitionAddress, dismissPersonaDetails: Bool) -> Effect<Action> {
		.run { send in
			let updatedDapp = try await authorizedDappsClient.getDetailedDapp(dAppID)
			await send(.internal(.dAppUpdated(updatedDapp)))
			if dismissPersonaDetails {
				await send(.child(.destination(.dismiss)))
			}
		} catch: { error, _ in
			errorQueue.schedule(error)
		}
	}

	private func disconnectDappEffect(dAppID: DappDefinitionAddress, networkID: NetworkID, delay: Duration? = .zero) -> Effect<Action> {
		.run { send in
			if let delay {
				try await clock.sleep(for: delay)
			}
			try await authorizedDappsClient.forgetAuthorizedDapp(dAppID, networkID)
			await send(.delegate(.dAppForgotten))
		} catch: { error, _ in
			errorQueue.schedule(error)
		}
	}
}

extension AlertState<DappDetails.Destination.Action.ConfirmDisconnectAlert> {
	static var confirmDisconnect: AlertState {
		AlertState {
			TextState(L10n.AuthorizedDapps.ForgetDappAlert.title)
		} actions: {
			ButtonState(role: .destructive, action: .confirmTapped) {
				TextState(L10n.AuthorizedDapps.ForgetDappAlert.forget)
			}
			ButtonState(role: .cancel, action: .cancelTapped) {
				TextState(L10n.Common.cancel)
			}
		} message: {
			TextState(L10n.AuthorizedDapps.ForgetDappAlert.message)
		}
	}
}
