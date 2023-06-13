import FeaturePrelude
import RadixConnect

// MARK: - ConnectUsingSecrets
public struct ConnectUsingSecrets: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var connectionPassword: ConnectionPassword
		public var isConnecting: Bool
		public var nameOfConnection: String
		public var focusedField: Field?

		public var isNameValid: Bool { !nameOfConnection.isEmpty }

		public init(
			connectionPassword: ConnectionPassword,
			isConnecting: Bool = false,
			focusedField: Field? = nil,
			nameOfConnection: String = ""
		) {
			self.focusedField = focusedField
			self.connectionPassword = connectionPassword
			self.isConnecting = isConnecting
			self.nameOfConnection = nameOfConnection
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
		case textFieldFocused(ConnectUsingSecrets.State.Field?)
		case nameOfConnectionChanged(String)
		case confirmNameButtonTapped
	}

	public enum InternalAction: Sendable, Equatable {
		case focusTextField(ConnectUsingSecrets.State.Field?)
		case establishConnectionResult(TaskResult<ConnectionPassword>)
		case cancelOngoingEffects
	}

	public enum DelegateAction: Sendable, Equatable {
		case connected(P2PLink)
	}

	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.continuousClock) var clock
	@Dependency(\.radixConnectClient) var radixConnectClient

	public init() {}

	private enum FocusFieldID {}
	private enum ConnectID {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return .send(.view(.textFieldFocused(.connectionName)))

		case let .textFieldFocused(focus):
			return .run { send in
				do {
					try await clock.sleep(for: .seconds(0.5))
					try Task.checkCancellation()
					await send(.internal(.focusTextField(focus)))
				} catch {
					/* noop */
					print("failed to sleep or task cancelled? error: \(String(describing: error))")
				}
			}
			.cancellable(id: FocusFieldID.self)

		case let .nameOfConnectionChanged(connectionName):
			state.nameOfConnection = connectionName.trimmingNewlines()
			return .none

		case .confirmNameButtonTapped:
			let connectionPassword = state.connectionPassword
			state.isConnecting = true
			return .run { send in
				await send(.internal(.establishConnectionResult(
					TaskResult(catching: {
						try await radixConnectClient.addP2PWithPassword(connectionPassword)
						return connectionPassword
					})
				)))
			}.cancellable(id: ConnectID.self)
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case .establishConnectionResult(.success):
			state.isConnecting = false
			let p2pLink = P2PLink(connectionPassword: state.connectionPassword, displayName: state.nameOfConnection)
			return .run { send in
				await send(.internal(.cancelOngoingEffects))
				await send(.delegate(.connected(p2pLink)))
			}

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
