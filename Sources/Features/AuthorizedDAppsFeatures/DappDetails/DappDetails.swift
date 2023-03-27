import AuthorizedDappsClient
import FeaturePrelude
import GatewayAPI

// MARK: - DappDetails
public struct DappDetails: Sendable, FeatureReducer {
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.gatewayAPIClient) var gatewayClient
	@Dependency(\.openURL) var openURL
	@Dependency(\.pasteboardClient) var pasteboardClient
	@Dependency(\.authorizedDappsClient) var authorizedDappsClient

	public struct FailedToLoadMetadata: Error, Hashable {}

	public typealias Store = StoreOf<Self>

	// MARK: State

	public struct State: Sendable, Hashable {
		public var dApp: Profile.Network.AuthorizedDappDetailed

		@Loadable
		public var metadata: GatewayAPI.EntityMetadataCollection? = nil

		@PresentationState
		public var presentedPersona: PersonaDetails.State? = nil

		@PresentationState
		public var confirmDisconnectAlert: AlertState<ViewAction.ConfirmDisconnectAlert>? = nil

		// TODO: This is part of a workaround to make SwiftUI actually dismiss the view
		public var isDismissed: Bool = false

		public init(dApp: Profile.Network.AuthorizedDappDetailed, presentedPersona: PersonaDetails.State? = nil) {
			self.dApp = dApp
			self.presentedPersona = presentedPersona
		}
	}

	// MARK: Action

	public enum ViewAction: Sendable, Equatable {
		case appeared
		case openURLTapped(URL)
		case copyAddressButtonTapped
		case fungibleTokenTapped(ComponentAddress)
		case nonFungibleTokenTapped(ComponentAddress)
		case personaTapped(Profile.Network.Persona.ID)
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
		case presentedPersona(PresentationAction<PersonaDetails.Action>)
	}

	// MARK: Reducer

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.ifLet(\.$presentedPersona, action: /Action.child .. ChildAction.presentedPersona) {
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
					try await gatewayClient.getEntityMetadata(dAppID.address)
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

		case let .personaTapped(id):
			guard let persona = state.dApp.detailedAuthorizedPersonas[id: id] else { return .none }
			state.presentedPersona = PersonaDetails.State(dAppName: state.dApp.displayName.rawValue,
			                                              dAppID: state.dApp.dAppDefinitionAddress,
			                                              networkID: state.dApp.networkID,
			                                              persona: persona)
			return .none

		case .dismissPersonaTapped:
			return .send(.child(.presentedPersona(.dismiss)))

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
		case .presentedPersona(.presented(.delegate(.personaDeauthorized))):
			let dAppID = state.dApp.dAppDefinitionAddress
			return .run { send in
				let updatedDapp = try await authorizedDappsClient.getDetailedDapp(dAppID)
				await send(.internal(.dAppUpdated(updatedDapp)))
				await send(.child(.presentedPersona(.dismiss)))
			} catch: { error, _ in
				errorQueue.schedule(error)
			}

		default:
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

			state.dApp = dApp
			return .none

		case .dAppForgotten:
			// TODO: This is part of a workaround to make SwiftUI actually dismiss the view
			state.isDismissed = true
			return .send(.delegate(.dAppForgotten))
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

// MARK: - Extensions

extension GatewayAPI.EntityMetadataCollection {
	var description: String? {
		self["description"]
	}

	var symbol: String? {
		self["symbol"]
	}

	var name: String? {
		self["name"]
	}

	var url: String? {
		self["url"]
	}

	subscript(key: String) -> String? {
		items.first { $0.key == key }?.value.asString
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
