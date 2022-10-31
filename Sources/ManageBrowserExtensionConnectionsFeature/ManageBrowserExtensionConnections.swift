import ComposableArchitecture
import Converse

// MARK: - ManageBrowserExtensionConnections
public struct ManageBrowserExtensionConnections: ReducerProtocol {
	public init() {
		// Tmp proof that we have solved SPM issue 5630 (failed to add Converse as a dependency.)
		_ = try! Connection.live(connectionSecrets: .random())
	}
}

public extension ManageBrowserExtensionConnections {
	func reduce(into _: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case .internal(.user(.dismiss)):
			return .run { send in
				await send(.coordinate(.dismiss))
			}
		case .coordinate:
			return .none
		}
	}
}
