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
		public var dApps: [DappDetails]? = nil

		public var personaList: PersonaList.State

		@PresentationState
		public var destination: Destination.State? = nil

		public init(
			dApp: Profile.Network.AuthorizedDappDetailed,
			metadata: GatewayAPI.EntityMetadataCollection? = nil,
			resources: Resources? = nil,
			dApps: [DappDetails]? = nil,
			personaDetails: PersonaDetails.State? = nil,
			destination: Destination.State? = nil
		) {
			self.dApp = dApp
			self.metadata = metadata
			self.resources = resources
			self.dApps = dApps
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
		public struct DappDetails: Identifiable, Hashable, Sendable {
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
		case associatedDappsLoaded(Loadable<[State.DappDetails]>)
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

			let dappDefinitionAddress = state.dApp.dAppDefinitionAddress
			let claimedEntities = state.metadata?.claimedEntities
			let dappDefinitions = try? state.metadata?.dappDefinitions?.compactMap(DappDefinitionAddress.init)

			return .run { send in
				if let claimedEntities, !claimedEntities.isEmpty {
					let result = await TaskResult {
						// FIXME: When we can be sure that resources point back to the dapp definition we should switch to the validating version
						try await resources(addresses: claimedEntities)
						// try await resources(addresses: claimedEntities, validated: dappDefinitionAddress)
					}
					await send(.internal(.resourcesLoaded(.init(result: result))))
				} else {
					await send(.internal(.resourcesLoaded(metadata.flatMap { _ in .idle })))
				}

				if let dappDefinitions, !dappDefinitions.isEmpty {
					let result = await TaskResult {
						try await dApps(addresses: dappDefinitions, validated: dappDefinitionAddress)
					}
					await send(.internal(.associatedDappsLoaded(.init(result: result))))
				} else {
					await send(.internal(.associatedDappsLoaded(metadata.flatMap { _ in .idle })))
				}
			}

		case let .resourcesLoaded(resources):
			state.$resources = resources
			return .none

		case let .associatedDappsLoaded(dApps):
			state.$dApps = dApps
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

	private func resources(addresses: [String]) async throws -> State.Resources {
		let allResourceItems = try await gatewayAPIClient.fetchResourceDetails(addresses)
			.items
			.compactMap(\.resourceDetails)

		return .init(fungible: allResourceItems.filter { $0.fungibility == .fungible },
		             nonFungible: allResourceItems.filter { $0.fungibility == .nonFungible })
	}

	private func resources(addresses: [String], validated dAppDefinitionAddress: DappDefinitionAddress) async throws -> State.Resources {
		let allResourceItems = try await gatewayAPIClient.fetchResourceDetails(addresses)
			.items
			.filter { $0.metadata.dappDefinition == dAppDefinitionAddress.address }
			.compactMap(\.resourceDetails)

		return .init(fungible: allResourceItems.filter { $0.fungibility == .fungible },
		             nonFungible: allResourceItems.filter { $0.fungibility == .nonFungible })
	}

	private func dApps(addresses: [DappDefinitionAddress], validated dAppDefinitionAddress: DappDefinitionAddress) async throws -> [State.DappDetails] {
		let allResourceItems = try await gatewayAPIClient.fetchResourceDetails(addresses)
			.items
			.filter { $0.metadata.dappDefinition == dAppDefinitionAddress.address }
			.compactMap(\.resourceDetails)

		return .init(fungible: allResourceItems.filter { $0.fungibility == .fungible },
		             nonFungible: allResourceItems.filter { $0.fungibility == .nonFungible })
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
