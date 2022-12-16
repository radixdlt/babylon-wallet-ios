import Common
import ComposableArchitecture
import ErrorQueue
import Foundation
import P2PConnectivityClient
import Peer
import SharedModels
import SwiftUI

// MARK: - ManageP2PClient
public struct ManageP2PClient: Sendable, ReducerProtocol {
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.p2pConnectivityClient) var p2pConnectivityClient
	public init() {}
}

public extension ManageP2PClient {
	func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case .internal(.view(.viewAppeared)):
			return .run { [id = state.id] send in
				await withThrowingTaskGroup(of: Void.self) { taskGroup in
					taskGroup.addTask {
						do {
							let statusUpdates = try await p2pConnectivityClient.getConnectionStatusAsyncSequence(id)
							for try await status in statusUpdates {
								assert(status.p2pClient.id == id)
								await send(.internal(.system(.connectionStatusResult(
									TaskResult.success(status.connectionStatus)
								))))
							}
						} catch {
							await send(.internal(.system(.connectionStatusResult(
								TaskResult.failure(error)
							))))
						}
					}
				}
			}

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
		#endif // DEBUG
		case .delegate:
			return .none
		}
	}
}
