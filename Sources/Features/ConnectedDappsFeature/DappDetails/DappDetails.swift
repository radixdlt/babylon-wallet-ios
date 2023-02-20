import FeaturePrelude
import GatewayAPI
import ProfileClient

// MARK: - DappDetails
public struct DappDetails: Sendable, FeatureReducer {
	@Dependency(\.gatewayAPIClient) var gatewayClient
	@Dependency(\.openURL) var openURL
	@Dependency(\.pasteboardClient) var pasteboardClient
	@Dependency(\.profileClient) var profileClient

	public struct FailedToLoadMetadata: Error, Hashable {}

	public typealias Store = StoreOf<Self>

	// MARK: State

	public struct State: Sendable, Hashable {
		public var dApp: OnNetwork.ConnectedDappDetailed

		@Loadable
		public var metadata: GatewayAPI.EntityMetadataCollection? = nil

		@PresentationState
		public var presentedPersona: PersonaDetails.State? = nil

		// TODO: This is part of a workaround to make SwiftUI actually dismiss the view
		public var isDismissed: Bool = false

		public init(dApp: OnNetwork.ConnectedDappDetailed, presentedPersona: PersonaDetails.State? = nil) {
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
		case personaTapped(OnNetwork.Persona.ID)
		case dismissPersonaTapped
		case forgetThisDappTapped
	}

	public enum DelegateAction: Sendable, Equatable {
		case dAppForgotten
	}

	public enum InternalAction: Sendable, Equatable {
		case metadataLoaded(Loadable<GatewayAPI.EntityMetadataCollection>)
		case dAppUpdated(OnNetwork.ConnectedDappDetailed)
	}

	public enum ChildAction: Sendable, Equatable {
		case presentedPersona(PresentationActionOf<PersonaDetails>)
	}

	// MARK: Reducer

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.presentationDestination(\.$presentedPersona, action: /Action.child .. ChildAction.presentedPersona) {
				PersonaDetails()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			state.$metadata = .loading
			let dAppID = state.dApp.dAppDefinitionAddress
			return .task {
				let metadata = try await gatewayClient.resourceDetailsByResourceIdentifier(dAppID.address).metadata
				return .internal(.metadataLoaded(.loaded(metadata)))
			} catch: { error in
				.internal(.metadataLoaded(.init(error)))
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
			return .none

		case let .nonFungibleTokenTapped(nft):
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
			// TODO: This is part of a workaround to make SwiftUI actually dismiss the view
			state.isDismissed = true
			let (dAppID, networkID) = (state.dApp.dAppDefinitionAddress, state.dApp.networkID)
			return .task {
				try await profileClient.forgetConnectedDapp(dAppID, networkID)
				return .delegate(.dAppForgotten)
			}
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case .presentedPersona(.presented(.delegate(.personaDisconnected))):
			let dAppID = state.dApp.dAppDefinitionAddress
			return .run { send in
				let updatedDapp = try await profileClient.getDetailedDapp(dAppID)
				await send(.internal(.dAppUpdated(updatedDapp)))
				await send(.child(.presentedPersona(.dismiss)))
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
			state.dApp = dApp
			return .none
		}
	}
}

// MARK: - Extensions

// We could even consider give EntityMetadataCollection support for dynamicMemberLookup
extension GatewayAPI.EntityMetadataCollection {
	var description: String? {
		self["description"]
	}

	subscript(key: String) -> String? {
		items.first { $0.key == key }?.value
	}
}

// MARK: - Loadable
@propertyWrapper
@dynamicMemberLookup
public enum Loadable<Value> {
	case notLoaded
	case loading
	case loaded(Value)
	case failed(LoadingError)

	subscript<T>(dynamicMember keyPath: KeyPath<Value, T>) -> Loadable<T> {
		switch self {
		case .notLoaded:
			return .notLoaded
		case .loading:
			return .loading
		case let .loaded(value):
			return .loaded(value[keyPath: keyPath])
		case let .failed(loadingError):
			return .failed(loadingError)
		}
	}

	public init(wrappedValue: Value?) {
		if let wrappedValue {
			self = .loaded(wrappedValue)
		} else {
			self = .notLoaded
		}
	}

	public init(_ error: Error) {
		let loadingError: LoadingError = error is BadHTTPResponseCode ? .badHTTPResponseCode : .unknown
		self = .failed(loadingError)
	}

	public var projectedValue: Self {
		get { self }
		set { self = newValue }
	}

	public var wrappedValue: Value? {
		get {
			guard case let .loaded(value) = self else { return nil }
			return value
		}
		set {
			if let newValue {
				self = .loaded(newValue)
			} else {
				self = .notLoaded
			}
		}
	}
}

// MARK: - LoadingError
public enum LoadingError: Hashable {
	case badHTTPResponseCode
	case unknown
}

// MARK: - Loadable + Equatable
extension Loadable: Equatable where Value: Equatable {}

// MARK: - Loadable + Hashable
extension Loadable: Hashable where Value: Hashable {}
