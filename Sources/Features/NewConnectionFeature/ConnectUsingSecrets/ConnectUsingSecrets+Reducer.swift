import ComposableArchitecture
import Converse

// MARK: - ConnectUsingSecrets
public struct ConnectUsingSecrets: Sendable, ReducerProtocol {
	public init() {}
}

public extension ConnectUsingSecrets {
	func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
		//        switch action {
		//        case .internal(.view(.appeared)):
		//                        let connection = Connection.live(connectionSecrets: connectionSecrets)
		//            //            state.connectUsingPassword = ConnectUsingSecrets.State(connection: connection)
		//            //            return .none
		//            //
		//            //        case let .internal(.system(.initConnectionSecretsResult(.failure(error)))):
		//            //            errorQueue.schedule(error)
		//            //            return .none
//
		////        case let .child(.inputP2PConnectionPassword(.delegate(.connect(password)))):
		////            return .run { send in
		////                await send(
		////                    .internal(.system(.initConnectionSecretsResult(
		////                        TaskResult<ConnectionSecrets> {
		////                            try ConnectionSecrets.from(connectionPassword: password)
		////                        }
		////                    )))
		////                )
		////            }
		//        }

		.none
	}
}
