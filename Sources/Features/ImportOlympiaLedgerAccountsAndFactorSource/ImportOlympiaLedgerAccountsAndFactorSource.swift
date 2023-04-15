import FactorSourcesClient
import FeaturePrelude
import RadixConnectClient

// MARK: - ImportOlympiaLedgerAccountsAndFactorSource
public struct ImportOlympiaLedgerAccountsAndFactorSource: Sendable, FeatureReducer {
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
			info: P2P.ConnectorExtension.Response.LedgerHardwareWallet.Success.GetDeviceInfo,
			interactionID: P2P.LedgerHardwareWallet.InteractionId
		)
		case broadcasted(interactionID: P2P.LedgerHardwareWallet.InteractionId)
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
			return .run { send in
				let interactionID = P2P.LedgerHardwareWallet.InteractionId.random()
				try await radixConnectClient.sendRequest(.connectorExtension(.ledgerHardwareWallet(.init(
					interactionID: interactionID,
					request: .getDeviceInfo
				))), .broadcastToAllPeers)

				await send(.internal(.broadcasted(interactionID: interactionID)))
			} catch: { error, _ in
				loggerGlobal.error("Failed to send message to Connector Extension, error: \(error)")
			}
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .gotDeviceInfoResponse(info, interactionID):
			return .none
		case let .broadcasted(interactionID):
			return .none
		}
	}

	private func listenForResponses() -> EffectTask<Action> {
		.run { send in
			await radixConnectClient.loadFromProfileAndConnectAll()

			for try await incomingResponse in await radixConnectClient.receiveResponses(/P2P.RTCMessageFromPeer.Response.connectorExtension .. /P2P.ConnectorExtension.Response.ledgerHardwareWallet) {
				guard !Task.isCancelled else {
					return
				}

				guard
					// ignore receive/decode errors for now
					let response = try? incomingResponse.result.get()
				else { continue }

				switch response.response {
				case let .success(.getDeviceInfo(info)):
					await send(.internal(
						.gotDeviceInfoResponse(
							info: info,
							interactionID: response.interactionID
						)
					))
				case let .failure(errorFromConnectorExtension):
					throw errorFromConnectorExtension
				default: break
				}
			}
		} catch: { error, _ in
			errorQueue.schedule(error)
		}
	}
}
