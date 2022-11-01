import ComposableArchitecture
import Converse
import InputPasswordFeature

// MARK: - ManageBrowserExtensionConnections
public struct ManageBrowserExtensionConnections: ReducerProtocol {
	public init() {
		// Tmp proof that we have solved SPM issue 5630 (failed to add Converse as a dependency.)
		_ = try! Connection.live(connectionSecrets: .random())
	}
}

public extension ManageBrowserExtensionConnections {
	var body: some ReducerProtocol<State, Action> {
		Reduce(self.core)
			.ifLet(\
				.inputBrowserExtensionConnectionPassword,
				action: /ManageBrowserExtensionConnections.Action.inputBrowserExtensionConnectionPassword) {
					InputPassword()
			}
			._printChanges()
	}

	func core(state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case .internal(.user(.dismiss)):
			return .run { send in
				await send(.coordinate(.dismiss))
			}
		case .internal(.user(.addNewConnection)):
			state.inputBrowserExtensionConnectionPassword = .init()
			return .none
		case let .inputBrowserExtensionConnectionPassword(.connect(password)):
			fatalError("password: \(password)")
		case .inputBrowserExtensionConnectionPassword:
			return .none
		case .coordinate:
			return .none
		}
	}
}
