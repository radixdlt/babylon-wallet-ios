import FeaturePrelude
import RadixConnect

// MARK: - ConnectUsingSecrets
public struct ConnectUsingSecrets: Sendable, ReducerProtocol {
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.mainQueue) var mainQueue
	@Dependency(\.p2pConnectivityClient) var p2pConnectivityClient
	public init() {}
}

extension ConnectUsingSecrets {
	private enum FocusFieldID {}
	private enum ConnectID {}
	public func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case .internal(.view(.task)):
			let connectionPassword = state.connectionSecrets

			return .run { send in
				await send(.internal(.system(.establishConnectionResult(
					TaskResult(catching: {
						try await p2pConnectivityClient.addP2PWithSecrets(connectionPassword)
						return connectionPassword
					})
				))))
			}.cancellable(id: ConnectID.self)

		case .internal(.view(.appeared)):
			return .task {
				return .view(.textFieldFocused(.connectionName))
			}
			.cancellable(id: FocusFieldID.self)

		case .internal(.system(.establishConnectionResult(.success))):
			state.isPromptingForName = true
			return .none

		case let .internal(.view(.textFieldFocused(focus))):
			return .run { send in
				do {
					try await self.mainQueue.sleep(for: .seconds(0.5))
					try Task.checkCancellation()
					await send(.internal(.system(.focusTextField(focus))))
				} catch {
					/* noop */
					print("failed to sleep or task cancelled? error: \(String(describing: error))")
				}
			}
			.cancellable(id: FocusFieldID.self)

		case let .internal(.system(.focusTextField(focus))):
			state.focusedField = focus
			return .none

		case .internal(.view(.confirmNameButtonTapped)):
			let p2pClient = P2PClient(connectionPassword: state.connectionSecrets, displayName: state.nameOfConnection)
			return .run { send in
				await send(.delegate(.connected(p2pClient)))
			}

		case let .internal(.view(.nameOfConnectionChanged(connectionName))):
			state.nameOfConnection = connectionName
			state.isNameValid = !connectionName.trimmed().isEmpty
			return .none

		case let .internal(.system(.establishConnectionResult(.failure(error)))):
			errorQueue.schedule(error)
			state.isConnecting = false
			return .none

		case .delegate:
			return .cancel(ids: [FocusFieldID.self, ConnectID.self])
		}
	}
}
