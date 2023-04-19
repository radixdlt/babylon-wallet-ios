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
	@Dependency(\.pasteboardClient) var pasteboardClient
	@Dependency(\.authorizedDappsClient) var authorizedDappsClient
	@Dependency(\.cacheClient) var cacheClient

	public struct FailedToLoadMetadata: Error, Hashable {}

	public typealias Store = StoreOf<Self>

	// MARK: State

	public struct State: Sendable, Hashable {
		public var dApp: Profile.Network.AuthorizedDappDetailed

		@Loadable
		public var metadata: GatewayAPI.EntityMetadataCollection? = nil

		@PresentationState
		public var personaDetails: PersonaDetails.State? = nil

		@PresentationState
		public var confirmDisconnectAlert: AlertState<ViewAction.ConfirmDisconnectAlert>? = nil

		public var personaList: PersonaList.State

		public init(dApp: Profile.Network.AuthorizedDappDetailed, personaDetails: PersonaDetails.State? = nil) {
			self.dApp = dApp
			self.personaDetails = personaDetails
			self.personaList = .init(dApp: dApp)
		}
	}

	// MARK: Action

	public enum ViewAction: Sendable, Equatable {
		case appeared
		case openURLTapped(URL)
		case copyAddressButtonTapped
		case fungibleTokenTapped(ComponentAddress)
		case nonFungibleTokenTapped(ComponentAddress)
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

		case .copyAddressButtonTapped:
			let address = state.dApp.dAppDefinitionAddress
			return .fireAndForget {
				pasteboardClient.copyString(address.address)
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
			return .none
		case let .dAppUpdated(dApp):
			guard !dApp.detailedAuthorizedPersonas.isEmpty else {
				return disconnectDappEffect(state: state)
			}
			let previousPersonaDetails = state.personaDetails
			state = .init(dApp: dApp, personaDetails: previousPersonaDetails)

			return .none

		case .dAppForgotten:
			return .task {
				await dismiss()
				return .delegate(.dAppForgotten)
			}
		}
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
