import FeaturePrelude

// MARK: - ConnectedDApps
public struct ConnectedDApps: Sendable, FeatureReducer {
	public typealias Store = StoreOf<Self>

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.presentationDestination(\.$selectedDApp, action: /Action.child .. ChildAction.selectedDApp) {
				DAppProfile()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return .none
		case let .didSelectDApp(name):
			// TODO: • This proxying is only necessary because of our strict view/child separation
			return .send(.child(.selectedDApp(.present(.init(name: name)))))
		}
	}
}

// MARK: ConnectedDApps.State
public extension ConnectedDApps {
	struct State: Sendable, Hashable {
		@PresentationState public var selectedDApp: DAppProfile.State?

		public let dApps: [DAppRowModel]

		public init(selectedDApp: DAppProfile.State? = nil) {
			self.selectedDApp = selectedDApp
			self.dApps = [
				.init(name: "NBA Top Shot", thumbnail: .placeholder),
				.init(name: "Megaswap", thumbnail: .placeholder),
				.init(name: "UniDEX", thumbnail: .placeholder),
				.init(name: "Nas Black", thumbnail: .placeholder),
			]
		}
	}
}

// MARK: - DAppRowModel
public struct DAppRowModel: Identifiable, Hashable {
	public let id: UUID = .init()
	public let name: String
	public let thumbnail: URL
}

// MARK: - Action

public extension ConnectedDApps {
	enum ViewAction: Sendable, Equatable {
		case appeared
		case didSelectDApp(String)
	}

	enum DelegateAction: Sendable, Equatable {}

	enum ChildAction: Sendable, Equatable {
		case selectedDApp(PresentationActionOf<DAppProfile>)
	}
}
