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
		public let dApp: OnNetwork.ConnectedDappDetailed

		@Loadable
		public var metadata: Metadata? = nil

		@PresentationState
		public var presentedPersona: PersonaDetails.State? = nil

		public init(dApp: OnNetwork.ConnectedDappDetailed, presentedPersona: PersonaDetails.State? = nil) {
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
		case forgetThisDappTapped
	}

	public enum DelegateAction: Sendable, Equatable {
		case dAppForgotten(id: OnNetwork.ConnectedDapp.ID, networkID: NetworkID)
	}

	public enum InternalAction: Sendable, Equatable {
		case metadataLoaded(Loadable<State.Metadata>)
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
				let metadataEntities = try await gatewayClient.resourceDetailsByResourceIdentifier(dAppID.address).metadata
				let metadata = State.Metadata(metadataEntities)
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

		case let .tokenTapped(token):
			return .none

		case let .nftTapped(nft):
			return .none

		case let .personaTapped(id):
			guard let persona = state.dApp.detailedAuthorizedPersonas[id: id] else { return .none }
			let presented = PersonaDetails.State(dAppName: state.dApp.displayName.rawValue, persona: persona)
			return .send(.child(.presentedPersona(.present(presented))))

		case .forgetThisDappTapped:
			let dAppID = state.dApp.dAppDefinitionAddress
			let networkID = state.dApp.networkID

			return .task {
				try await profileClient.forgetConnectedDapp(dAppID, networkID)
				return .delegate(.dAppForgotten(id: dAppID, networkID: networkID))
			}
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

// TODO: • Move or use existing DappMetadata from DappInteraction
extension DappDetails.State.Metadata {
	init(_ metadata: GatewayAPI.EntityMetadataCollection) {
		self.description = metadata["description"]
		self.domain = metadata["domain"]
	}
}

// We could even consider give EntityMetadataCollection support for dynamicMemberLookup
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
