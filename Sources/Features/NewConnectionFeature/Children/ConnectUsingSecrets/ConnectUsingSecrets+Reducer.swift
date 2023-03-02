import FeaturePrelude
import RadixConnect

// MARK: - ConnectUsingSecrets
public struct ConnectUsingSecrets: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var connectionSecrets: ConnectionSecrets
		public var isConnecting: Bool
		public var isPromptingForName: Bool
		public var nameOfConnection: String
		public var idOfNewConnection: P2PConnectionID?
		public var isNameValid: Bool
		@BindableState public var focusedField: Field?

		public init(
			connectionSecrets: ConnectionSecrets,
			isConnecting: Bool = true,
			idOfNewConnection: P2PConnectionID? = nil,
			focusedField: Field? = nil,
			isPromptingForName: Bool = false,
			nameOfConnection: String = "",
			isNameValid: Bool = false
		) {
			self.focusedField = focusedField
			self.connectionSecrets = connectionSecrets
			self.isConnecting = isConnecting
			self.isPromptingForName = isPromptingForName
			self.nameOfConnection = nameOfConnection
			self.idOfNewConnection = idOfNewConnection
			self.isNameValid = isNameValid
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case task
		case appeared
		case textFieldFocused(ConnectUsingSecrets.State.Field?)
		case nameOfConnectionChanged(String)
		case confirmNameButtonTapped
	}

	public enum InternalAction: Sendable, Equatable {
		case focusTextField(ConnectUsingSecrets.State.Field?)
		case establishConnectionResult(TaskResult<P2PConnectionID>)
		case cancelOngoingEffects
	}

	public enum DelegateAction: Sendable, Equatable {
		case connected(P2P.ClientWithConnectionStatus)
	}

	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.mainQueue) var mainQueue
<<<<<<< HEAD
	@Dependency(\.p2pConnectivityClient) var p2pConnectivityClient
	public init() {}
}
=======
>>>>>>> main

	public init() {}

	private enum FocusFieldID {}
	private enum ConnectID {}
<<<<<<< HEAD
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
=======

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .task:
			return .run { [connectionPassword = state.connectionSecrets.connectionPassword] send in
				await send(.internal(.establishConnectionResult(
					TaskResult {
						try await P2PConnections.shared.add(
							connectionPassword: connectionPassword,
							connectMode: .connect(force: true, inBackground: false),
							emitConnectionsUpdate: false // we wanna emit after we have added the connectionID to Profile
						)
					}
				)))
			}
			.cancellable(id: ConnectID.self)
>>>>>>> main

		case .appeared:
			return .task {
				return .view(.textFieldFocused(.connectionName))
			}
			.cancellable(id: FocusFieldID.self)

<<<<<<< HEAD
		case .internal(.system(.establishConnectionResult(.success))):
			state.isPromptingForName = true
			return .none

		case let .internal(.view(.textFieldFocused(focus))):
=======
		case let .textFieldFocused(focus):
>>>>>>> main
			return .run { send in
				do {
					try await self.mainQueue.sleep(for: .seconds(0.5))
					try Task.checkCancellation()
					await send(.internal(.focusTextField(focus)))
				} catch {
					/* noop */
					print("failed to sleep or task cancelled? error: \(String(describing: error))")
				}
			}
			.cancellable(id: FocusFieldID.self)

		case let .nameOfConnectionChanged(connectionName):
			state.nameOfConnection = connectionName
			state.isNameValid = !connectionName.trimmed().isEmpty
			return .none

<<<<<<< HEAD
		case .internal(.view(.confirmNameButtonTapped)):
			let p2pClient = P2PClient(connectionPassword: state.connectionSecrets, displayName: state.nameOfConnection)
			return .run { send in
				await send(.delegate(.connected(p2pClient)))
=======
		case .confirmNameButtonTapped:
			// determines if we are indeed connected...
			guard let _ = state.idOfNewConnection else {
				// invalid state
				return .none
			}

			let clientWithConnectionStatus = P2P.ClientWithConnectionStatus(
				p2pClient: .init(
					connectionPassword: state.connectionSecrets.connectionPassword,
					displayName: state.nameOfConnection.trimmed()
				),
				connectionStatus: .connected
			)

			return .run { send in
				await send(.internal(.cancelOngoingEffects))
				await send(.delegate(.connected(clientWithConnectionStatus)))
>>>>>>> main
			}
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .establishConnectionResult(.success(idOfNewConnection)):
			state.idOfNewConnection = idOfNewConnection
			state.isConnecting = false
			state.isPromptingForName = true
			return .none

		case let .focusTextField(focus):
			state.focusedField = focus
			return .none

		case let .establishConnectionResult(.failure(error)):
			errorQueue.schedule(error)
			state.isConnecting = false
			return .none

		case .cancelOngoingEffects:
			return .cancel(ids: [FocusFieldID.self, ConnectID.self])
		}
	}
}
