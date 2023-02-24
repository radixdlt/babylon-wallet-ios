import FeaturePrelude
import P2PConnectivityClient

// MARK: - ManageP2PClient
public struct ManageP2PClient: Sendable, ReducerProtocol {
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.p2pConnectivityClient) var p2pConnectivityClient
	public init() {}
}

extension ManageP2PClient {
	private enum ConnectionUpdateTasksID {}
	public func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case .internal(.view(.viewAppeared)):
                        return .run { [id = state.client.id] send in
                                await withThrowingTaskGroup(of: Void.self) { taskGroup in
                                        _ = taskGroup.addTaskUnlessCancelled {
                                                //						do {
                                                //							for try await status in try await p2pConnectivityClient.getConnectionStatusAsyncSequence(id) {
                                                //								guard !Task.isCancelled else { return }
                                                //								assert(status.p2pClient.id == id)
                                                //								await send(.internal(.system(.connectionStatusResult(
                                                //									TaskResult.success(status.connectionStatus)
                                                //								))))
                                                //							}
                                                //						} catch {
                                                //							await send(.internal(.system(.connectionStatusResult(
                                                //								TaskResult.failure(error)
                                                //							))))
                                                //						}
                                                //					}
                                                //					#if DEBUG
                                                //					_ = taskGroup.addTaskUnlessCancelled {
                                                //						do {
                                                //							for try await webSocketStatus in try await p2pConnectivityClient._debugWebsocketStatusAsyncSequence(id) {
                                                //								guard !Task.isCancelled else { return }
                                                //								await send(.internal(.system(.webSocketStatusResult(.success(webSocketStatus)))))
                                                //							}
                                                //						} catch {
                                                //							await send(.internal(.system(.webSocketStatusResult(.failure(error)))))
                                                //						}
                                                //					}
                                                //					_ = taskGroup.addTaskUnlessCancelled {
                                                //						do {
                                                //							for try await dataChannelState in try await p2pConnectivityClient._debugDataChannelStatusAsyncSequence(id) {
                                                //								guard !Task.isCancelled else { return }
                                                //								await send(.internal(.system(.dataChannelStateResult(.success(dataChannelState)))))
                                                //							}
                                                //						} catch {
                                                //							await send(.internal(.system(.dataChannelStateResult(.failure(error)))))
                                                //						}
                                                //					}
                                                //					#endif
                                        }
                                }
                        }
			.cancellable(id: ConnectionUpdateTasksID.self)

		case let .internal(.system(.connectionStatusResult(.success(newStatus)))):
			state.connectionStatus = newStatus
			return .none

		case let .internal(.system(.connectionStatusResult(.failure(error)))):
			errorQueue.schedule(error)
			return .none

		case .internal(.view(.deleteConnectionButtonTapped)):
			return .run { send in
				await send(.delegate(.deleteConnection))
			}
		#if DEBUG
		case .internal(.view(.sendTestMessageButtonTapped)):
			return .run { send in
				await send(.delegate(.sendTestMessage))
			}
		case let .internal(.system(.webSocketStatusResult(.success(webSocketStatus)))):
			state.webSocketState = webSocketStatus
			return .none

		case let .internal(.system(.webSocketStatusResult(.failure(error)))):
			errorQueue.schedule(error)
			return .none

		case let .internal(.system(.dataChannelStateResult(.success(dataChannelState)))):
			state.dataChannelStatus = dataChannelState
			return .none

		case let .internal(.system(.dataChannelStateResult(.failure(error)))):
			errorQueue.schedule(error)
			return .none

		#endif
		case .delegate:
			return .cancel(id: ConnectionUpdateTasksID.self)
		}
	}
}
