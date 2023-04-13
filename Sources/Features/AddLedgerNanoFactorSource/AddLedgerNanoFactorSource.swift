import FactorSourcesClient
import FeaturePrelude
import RadixConnectClient

// MARK: - AddLedgerNanoFactorSource
public struct AddLedgerNanoFactorSource: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var outgoingInteractionIDs: Set<P2P.LedgerHardwareWallet.InteractionId>?

		public init(
		) {}
	}

	public enum ViewAction: Sendable, Equatable {
		case task
		case mockLedgerNanoAdded
		case sendAddLedgerRequestButtonTapped
	}

	public enum InternalAction: Sendable, Equatable {
		case gotDeviceInfoResponse(
			info: P2P.FromConnectorExtension.LedgerHardwareWallet.Success.GetDeviceInfo,
			interactionID: P2P.LedgerHardwareWallet.InteractionId
		)
	}

	public enum DelegateAction: Sendable, Equatable {
		case completed(FactorSourceID)
	}

	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.radixConnectClient) var radixConnectClient
	@Dependency(\.factorSourcesClient) var factorSourcesClient

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .mockLedgerNanoAdded:
			let factorSourceIDMocked = try! FactorSourceID(hex: "deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef")
			return .send(.delegate(.completed(
				factorSourceIDMocked
			)))

		case .task:
			return listenForResponses()

		case .sendAddLedgerRequestButtonTapped:
			//            return .fireAndForget {
			//                for link in try await radixConnectClient.getP2PLinks() {
			//                    let interactionID = P2P.LedgerHardwareWallet.InteractionId.random()
			//                    let connectionId = link.id
//
			//                    let peerConnectionId: PeerConnectionID = link.
			//                    let request: P2P.ToConnectorExtension.LedgerHardwareWallet = .init(
			//                        interactionID: interactionID,
			//                        request: .getDeviceInfo
			//                    )
//
			//                    let message = P2P.RTCOutgoingMessage(
			//                        connectionId: connectionId,
			//                        content: P2P.RTCOutgoingMessage.PeerConnectionMessage(
			//                            peerConnectionId: peerConnectionId,
			//                            content: .connectorExtension(.ledgerHardwareWallet(request))
			//                        )
			//                    )
//
			//                    try await radixConnectClient.sendMessage(message)
//
			//                }
//
//			} catch: { error, _ in
//				loggerGlobal.error("Failed to send message to Connector Extension, error: \(error)")
//			}
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .gotDeviceInfoResponse(info, interactionID):
			return .none
		}
	}

	private func listenForResponses() -> EffectTask<Action> {
		.run { send in
			await radixConnectClient.loadFromProfileAndConnectAll()

			for try await incomingMessage in await radixConnectClient.receiveMessages() {
				guard !Task.isCancelled else {
					return
				}
				guard let info = try? incomingMessage.result.get().getDeviceInfoResponse() else {
					return
				}
				let ledgerHardwareWalletMessage = try incomingMessage.result.get().responseLedgerHardwareWallet()
				await send(.internal(.gotDeviceInfoResponse(info: info, interactionID: ledgerHardwareWalletMessage.interactionID)))
			}
		} catch: { error, _ in
			errorQueue.schedule(error)
		}
	}
}
