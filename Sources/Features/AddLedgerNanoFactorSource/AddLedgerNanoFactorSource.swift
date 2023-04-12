import FeaturePrelude
import RadixConnectClient

// MARK: - AddLedgerNanoFactorSource
public struct AddLedgerNanoFactorSource: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public init() {}
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
		case finishedButtonTapped
	}

	public enum DelegateAction: Sendable, Equatable {
		case completed(FactorSourceID)
	}

	@Dependency(\.radixConnectClient) var radixConnectClient

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return .none
		case .finishedButtonTapped:
			let factorSourceIDMocked = try! FactorSourceID(hex: "deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef")
			return .send(.delegate(.completed(
				factorSourceIDMocked
			)))

			//            do {
			//                let response: P2P.RTCOutgoingMessage =
			//                _ = try await radixConnectClient.sendMessage(response)
			//                if !isTransactionResponse {
			//                    await send(.internal(.sentResponseToDapp(response.peerMessage.content, for: request, dappMetadata)))
			//                }
			//            } catch {
			//                if !isTransactionResponse {
			//                    await send(.internal(.failedToSendResponseToDapp(response, for: request, dappMetadata, reason: error.localizedDescription)))
			//                }
			//            }
		}
	}
}
