import ComposableArchitecture

public struct NonFungibleResourceAsset: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable, Identifiable {
		public typealias ID = String
		public var id: ID { token.id.toRawString() }

		public let resourceImage: URL?
		public let resourceName: String?
		public let resourceAddress: ResourceAddress
		public let atLedgerState: AtLedgerState
		public let token: OnLedgerEntity.NonFungibleToken
		public var nftGlobalID: NonFungibleGlobalId {
			token.id
		}

		@PresentationState
		public var destination: Destination.State? = nil
	}

	public enum ViewAction: Equatable, Sendable {
		case resourceTapped
	}

	public struct Destination: DestinationReducer {
		public enum State: Sendable, Hashable {
			case details(NonFungibleTokenDetails.State)
		}

		public enum Action: Sendable, Equatable {
			case details(NonFungibleTokenDetails.Action)
		}

		public var body: some ReducerOf<Self> {
			Scope(state: /State.details, action: /Action.details) {
				NonFungibleTokenDetails()
			}
		}
	}

	public init() {}

	public var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(destinationPath, action: /Action.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .resourceTapped:
			state.destination = .details(.init(
				resourceAddress: state.resourceAddress,
				token: state.token,
				ledgerState: state.atLedgerState
			))
			return .none
		}
	}
}
