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
		public var tokens: Tokens? = nil

		public var personaList: PersonaList.State

		@PresentationState
		public var personaDetails: PersonaDetails.State? = nil

		@PresentationState
		public var confirmDisconnectAlert: AlertState<ViewAction.ConfirmDisconnectAlert>? = nil

		public init(
			dApp: Profile.Network.AuthorizedDappDetailed,
			metadata: GatewayAPI.EntityMetadataCollection? = nil,
			tokens: Tokens? = nil,
			personaDetails: PersonaDetails.State? = nil
		) {
			self.dApp = dApp
			self.metadata = metadata
			self.tokens = tokens
			self.personaDetails = personaDetails
			self.personaList = .init(dApp: dApp)
		}

		public struct Tokens: Hashable, Sendable {
			public var fungible: [ResourceDetails]
			public var nonFungible: [ResourceDetails]

			// TODO: This should be consolidated with other types that represent resources
			public struct ResourceDetails: Identifiable, Hashable, Sendable {
				public var id: ResourceAddress { resourceAddress }

				public let resourceAddress: ResourceAddress
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
	}

	// MARK: Action

	public enum ViewAction: Sendable, Equatable {
		case appeared
		case openURLTapped(URL)
		case fungibleTokenTapped(ResourceAddress)
		case nonFungibleTokenTapped(ResourceAddress)
		case dismissPersonaTapped
		case forgetThisDappTapped
		case confirmDisconnectAlert(PresentationAction<ConfirmDisconnectAlert>)

		public enum ConfirmDisconnectAlert: Sendable, Equatable {
			case confirmTapped
			case cancelTapped
		}
	}

	public enum DelegateAction: Sendable, Equatable {
		case dAppForgotten
	}

	public enum InternalAction: Sendable, Equatable {
		case metadataLoaded(Loadable<GatewayAPI.EntityMetadataCollection>)
		case tokensLoaded(Loadable<State.Tokens>)
		case dAppUpdated(Profile.Network.AuthorizedDappDetailed)
		case dAppForgotten
	}

	public enum ChildAction: Sendable, Equatable {
		case personaDetails(PresentationAction<PersonaDetails.Action>)
		case personas(PersonaList.Action)
	}

	// MARK: Reducer

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Scope(state: \.personaList, action: /Action.child .. ChildAction.personas) {
			PersonaList()
		}
		Reduce(core)
			.ifLet(\.$personaDetails, action: /Action.child .. ChildAction.personaDetails) {
				PersonaDetails()
			}
			.ifLet(\.$confirmDisconnectAlert, action: /Action.view .. ViewAction.confirmDisconnectAlert)
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			state.$metadata = .loading
			state.$tokens = .loading
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

		case let .fungibleTokenTapped(token):
			// TODO: Handle this
			return .none

		case let .nonFungibleTokenTapped(nft):
			// TODO: Handle this
			return .none

		case .dismissPersonaTapped:
			return .send(.child(.personaDetails(.dismiss)))

		case .forgetThisDappTapped:
			state.confirmDisconnectAlert = .confirmDisconnect
			return .none

		case .confirmDisconnectAlert(.presented(.confirmTapped)):
			return disconnectDappEffect(state: state)

		case .confirmDisconnectAlert:
			return .none
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case .personaDetails(.presented(.delegate(.personaDeauthorized))):
			let dAppID = state.dApp.dAppDefinitionAddress
			return update(dAppID: dAppID, dismissPersonaDetails: true)

		case .personaDetails(.presented(.delegate(.personaChanged))):
			let dAppID = state.dApp.dAppDefinitionAddress
			return update(dAppID: dAppID, dismissPersonaDetails: false)

		case .personaDetails:
			return .none

		case let .personas(.delegate(.openDetails(persona))):
			guard let detailedPersona = state.dApp.detailedAuthorizedPersonas[id: persona.id] else { return .none }
			state.personaDetails = PersonaDetails.State(.dApp(state.dApp, persona: detailedPersona))
			return .none

		case .personas:
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .metadataLoaded(metadata):
			state.$metadata = metadata
			if let claimedEntities = state.metadata?.claimedEntities, !claimedEntities.isEmpty {
				let dappDefinitionAddress = state.dApp.dAppDefinitionAddress
				return .task {
					let result = await TaskResult {
						try await tokens(addresses: claimedEntities)
//						try await tokens(addresses: claimedEntities, validated: dappDefinitionAddress)
					}
					return .internal(.tokensLoaded(.init(result: result)))
				}
			} else {
				state.$tokens = metadata.flatMap { _ in .idle }
				return .none
			}

		case let .tokensLoaded(tokens):
			state.$tokens = tokens
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

	private func tokens(addresses: [String]) async throws -> State.Tokens {
		let allResourceItems = try await gatewayAPIClient.fetchResourceDetails(addresses)
			.items
			.compactMap(\.resourceDetails)

		return .init(fungible: allResourceItems.filter { $0.fungibility == .fungible },
		             nonFungible: allResourceItems.filter { $0.fungibility == .nonFungible })
	}

	private func tokens(addresses: [String], validated dAppDefinitionAddress: DappDefinitionAddress) async throws -> State.Tokens {
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
				await send(.child(.personaDetails(.dismiss)))
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
	var resourceDetails: DappDetails.State.Tokens.ResourceDetails? {
		guard let fungibility else { return nil }
		return .init(resourceAddress: .init(address: address),
		             fungibility: fungibility,
		             name: metadata.name ?? L10n.DAppDetails.unknownTokenName,
		             symbol: metadata.symbol,
		             description: metadata.description,
		             iconURL: metadata.iconURL)
	}

	private var fungibility: DappDetails.State.Tokens.ResourceDetails.Fungibility? {
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

extension AlertState<DappDetails.ViewAction.ConfirmDisconnectAlert> {
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
