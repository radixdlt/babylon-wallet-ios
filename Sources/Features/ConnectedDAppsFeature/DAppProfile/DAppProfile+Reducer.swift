import FeaturePrelude
import GatewayAPI
import ProfileClient

// MARK: - DAppProfile
public struct DAppProfile: Sendable, FeatureReducer {
	public struct FailedToLoadMetadata: Error, Hashable {}

	@Dependency(\.gatewayAPIClient) var gatewayClient
	@Dependency(\.openURL) var openURL
	@Dependency(\.pasteboardClient) var pasteboardClient
	@Dependency(\.profileClient) var profileClient

	public typealias Store = StoreOf<Self>

	// MARK: State

	public struct State: Sendable, Hashable {
		public let dApp: OnNetwork.ConnectedDappDetailed

		@Loadable
		public var metadata: Metadata? = nil

		@PresentationState
		public var presentedPersona: PersonaProfile.State? = nil

		init(dApp: OnNetwork.ConnectedDappDetailed, presentedPersona: PersonaProfile.State? = nil) {
			self.dApp = dApp
			self.presentedPersona = presentedPersona
		}

		public struct Metadata: Sendable, Hashable {
			let description: String?
			let domain: String?
		}
	}

	// MARK: Action

	public enum ViewAction: Sendable, Equatable {
		case appeared
		case openURLTapped(URL)
		case copyAddressButtonTapped
		case tokenTapped(UUID)
		case nftTapped(UUID)
		case personaTapped(OnNetwork.Persona.ID)
		case forgetThisDApp
	}

	public enum DelegateAction: Sendable, Equatable {
		case forgetDApp(id: OnNetwork.ConnectedDapp.ID, networkID: NetworkID)
	}

	public enum InternalAction: Sendable, Equatable {
		case metadataLoaded(Loadable<State.Metadata>)
	}

	public enum ChildAction: Sendable, Equatable {
		case presentedPersona(PresentationActionOf<PersonaProfile>)
	}

	// MARK: Reducer

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.presentationDestination(\.$presentedPersona, action: /Action.child .. ChildAction.presentedPersona) {
				PersonaProfile()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			state.$metadata = .loading
			let dAppID = state.dApp.dAppDefinitionAddress
			return .task {
				let metadataEntities = try await gatewayClient.resourceDetailsByResourceIdentifier(dAppID.address).metadata
				let metadata = State.Metadata(metadataEntities)
				return .internal(.metadataLoaded(.loaded(metadata)))
			} catch: { error in
				.internal(.metadataLoaded(.failed(error is BadHTTPResponseCode ? .badHTTPResponseCode : .unknown)))
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

		case let .tokenTapped(token):
			return .none

		case let .nftTapped(nft):
			return .none

		case let .personaTapped(id):
			guard let persona = state.dApp.detailedAuthorizedPersonas[id: id] else { return .none }
			let presented = PersonaProfile.State(dAppName: state.dApp.displayName.rawValue, persona: persona)
			return .send(.child(.presentedPersona(.present(presented))))

		case .forgetThisDApp:
			let dAppID = state.dApp.dAppDefinitionAddress
			let networkID = state.dApp.networkID
			return .send(.delegate(.forgetDApp(id: dAppID, networkID: networkID)))
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .metadataLoaded(metadata):
			state.$metadata = metadata
			return .none
		}
	}
}

extension DAppProfile.State.Metadata {
	init(_ metadata: GatewayAPI.EntityMetadataCollection) {
		self.description = metadata["description"]
		self.domain = metadata["domain"]
	}
}

extension GatewayAPI.EntityMetadataCollection {
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

	public init(error: Error) {
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
