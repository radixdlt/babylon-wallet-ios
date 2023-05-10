import AuthorizedDappsClient
import CacheClient
import FeaturePrelude
import GatewayAPI
import PersonaDetailsFeature
import PersonasFeature

// MARK: - DappDetails
public struct DappDetails: Sendable, FeatureReducer {
	@Dependency(\.dismiss) var dismiss
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

		public var personaList: PersonaList.State

		@PresentationState
		public var destination: Destination.State? = nil

		public init(
			dApp: Profile.Network.AuthorizedDappDetailed,
			metadata: GatewayAPI.EntityMetadataCollection? = nil,
			resources: Resources? = nil,
			associatedDapps: [AssociatedDapp]? = nil,
			personaDetails: PersonaDetails.State? = nil,
			destination: Destination.State? = nil
		) {
			self.dApp = dApp
			self.metadata = metadata
			self.resources = resources
			self.associatedDapps = associatedDapps
			self.personaList = .init(dApp: dApp)
			self.destination = destination
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
		case fungibleTapped(ResourceAddress)
		case nonFungibleTapped(ResourceAddress)
		case dAppTapped(DappDefinitionAddress)
		case dismissPersonaTapped
		case forgetThisDappTapped
	}

	public enum DelegateAction: Sendable, Equatable {
		case dAppForgotten
	}

	public enum InternalAction: Sendable, Equatable {
		case metadataLoaded(Loadable<GatewayAPI.EntityMetadataCollection>)
		case resourcesLoaded(Loadable<State.Resources>)
		case associatedDappsLoaded(Loadable<[State.AssociatedDapp]>)
		case dAppUpdated(Profile.Network.AuthorizedDappDetailed)
		case dAppForgotten
	}

	public enum ChildAction: Sendable, Equatable {
		case personas(PersonaList.Action)
		case destination(PresentationAction<Destination.Action>)
	}

	// MARK: - Destination

	public struct Destination: ReducerProtocol {
		public enum State: Equatable, Hashable {
			case personaDetails(PersonaDetails.State)
			case confirmDisconnectAlert(AlertState<Action.ConfirmDisconnectAlert>)
		}

		public enum Action: Equatable {
			case personaDetails(PersonaDetails.Action)
			case confirmDisconnectAlert(ConfirmDisconnectAlert)

			public enum ConfirmDisconnectAlert: Sendable, Equatable {
				case confirmTapped
				case cancelTapped
			}
		}

		public var body: some ReducerProtocolOf<Self> {
			Scope(state: /State.personaDetails, action: /Action.personaDetails) {
				PersonaDetails()
			}
		}
	}

	// MARK: Reducer

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Scope(state: \.personaList, action: /Action.child .. ChildAction.personas) {
			PersonaList()
		}
		Reduce(core)
			.ifLet(\.$destination, action: /Action.child .. ChildAction.destination) {
				Destination()
			}
	}

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

		case let .fungibleTapped(address):
			// TODO: Handle this
			return .none

		case let .nonFungibleTapped(address):
			// TODO: Handle this
			return .none

		case let .dAppTapped(address):
			// TODO: Handle this
			return .none

		case .dismissPersonaTapped:
			guard case .personaDetails = state.destination else { return .none }
			return .send(.child(.destination(.dismiss)))

		case .forgetThisDappTapped:
			state.destination = .confirmDisconnectAlert(.confirmDisconnect)
			return .none
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .destination(.presented(destinationAction)):
			switch destinationAction {
			case .personaDetails(.delegate(.personaDeauthorized)):
				let dAppID = state.dApp.dAppDefinitionAddress
				return update(dAppID: dAppID, dismissPersonaDetails: true)

			case .personaDetails(.delegate(.personaChanged)):
				let dAppID = state.dApp.dAppDefinitionAddress
				return update(dAppID: dAppID, dismissPersonaDetails: false)

			case .confirmDisconnectAlert(.confirmTapped):
				return disconnectDappEffect(state: state)

			default:
				return .none
			}

		case .destination:
			return .none

		case let .personas(.delegate(.openDetails(persona))):
			guard let detailedPersona = state.dApp.detailedAuthorizedPersonas[id: persona.id] else { return .none }
			state.destination = .personaDetails(PersonaDetails.State(.dApp(state.dApp, persona: detailedPersona)))
			return .none

		case .personas:
			return .none
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

		case let .dAppUpdated(dApp):
			assert(dApp.dAppDefinitionAddress == state.dApp.dAppDefinitionAddress, "dAppUpdated called with wrong dApp")
			guard !dApp.detailedAuthorizedPersonas.isEmpty else {
				return disconnectDappEffect(state: state)
			}
			state.dApp = dApp

			return .none

		case .dAppForgotten:
			return .task {
				await dismiss()
				return .delegate(.dAppForgotten)
			}
		}
	}

	/// Loads any fungible and non-fungible resources associated with the dApp
	private func loadResources(
		metadata: GatewayAPI.EntityMetadataCollection,
		validated dappDefinitionAddress: DappDefinitionAddress
	) async -> Loadable<DappDetails.State.Resources> {
		guard let claimedEntities = metadata.claimedEntities, !claimedEntities.isEmpty else {
			return .idle
		}

		let result = await TaskResult {
			let allResourceItems = try await gatewayAPIClient.fetchResourceDetails(claimedEntities)
				.items
				// FIXME: Uncomment this when when we can rely on dApps conforming to the standards
				// .filter { $0.metadata.dappDefinition == dAppDefinitionAddress.address }
				.compactMap(\.resourceDetails)

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

	private func update(dAppID: DappDefinitionAddress, dismissPersonaDetails: Bool) -> EffectTask<Action> {
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

	private func disconnectDappEffect(state: State) -> EffectTask<Action> {
		let (dAppID, networkID) = (state.dApp.dAppDefinitionAddress, state.dApp.networkID)
		return .run { send in
			try await authorizedDappsClient.forgetAuthorizedDapp(dAppID, networkID)
			await send(.internal(.dAppForgotten))
		} catch: { error, _ in
			errorQueue.schedule(error)
		}
	}
}

extension GatewayAPI.StateEntityDetailsResponseItem {
	var resourceDetails: DappDetails.State.Resources.ResourceDetails? {
		guard let fungibility else { return nil }
		return .init(address: .init(address: address),
		             fungibility: fungibility,
		             name: metadata.name ?? L10n.DAppDetails.unknownTokenName,
		             symbol: metadata.symbol,
		             description: metadata.description,
		             iconURL: metadata.iconURL)
	}

	private var fungibility: DappDetails.State.Resources.ResourceDetails.Fungibility? {
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

extension AlertState<DappDetails.Destination.Action.ConfirmDisconnectAlert> {
	static var confirmDisconnect: AlertState {
		AlertState {
			TextState(L10n.DAppDetails.forgetDappAlertTitle)
		} actions: {
			ButtonState(role: .destructive, action: .confirmTapped) {
				TextState(L10n.DAppDetails.forgetDappAlertConfirm)
			}
			ButtonState(role: .cancel, action: .cancelTapped) {
				TextState(L10n.DAppDetails.forgetDappAlertCancel)
			}
		} message: {
			TextState(L10n.DAppDetails.forgetDappAlertMessage)
		}
	}
}
