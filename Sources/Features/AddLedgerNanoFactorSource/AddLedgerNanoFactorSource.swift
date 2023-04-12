import FactorSourcesClient
import FeaturePrelude
import RadixConnectClient

// MARK: - AddLedgerNanoFactorSource
public struct AddLedgerNanoFactorSource: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var links: IdentifiedArrayOf<P2PLink>
		public var selectedLink: P2PLink?

		public var interactionID: P2P.LedgerHardwareWallet.InteractionId?

		public init(
			links: IdentifiedArrayOf<P2PLink> = []
		) {
			self.links = links
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
		case task
		case sendAddLedgerRequestButtonTapped
		case selectedLink(P2PLink)
	}

	public enum InternalAction: Sendable, Equatable {
		case loadLinksResult(OrderedSet<P2PLink>)
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
		case .appeared:
			return .run { send in
				try await send(.internal(.loadLinksResult(
					radixConnectClient.getP2PLinks()
				)))
			} catch: { error, _ in
				loggerGlobal.error("Failed to load links from profile, error: \(error)")
				errorQueue.schedule(error)
			}

		case .task:
			return handleIncommingRequests()

		case .sendAddLedgerRequestButtonTapped:
			let interactionID = P2P.LedgerHardwareWallet.InteractionId.random()
			state.interactionID = interactionID
			return .run { _ in

				let connectionId: ConnectionPassword = {
					fatalError()
				}()

				let peerConnectionId: PeerConnectionID = {
					fatalError()
				}()

				let request: P2P.ToConnectorExtension.LedgerHardwareWallet = .init(
					interactionID: interactionID,
					request: .getDeviceInfo
				)

				let message = P2P.RTCOutgoingMessage(
					connectionId: connectionId,
					content: P2P.RTCOutgoingMessage.PeerConnectionMessage(
						peerConnectionId: peerConnectionId,
						content: .connectorExtension(.ledgerHardwareWallet(request))
					)
				)

				try await radixConnectClient.sendMessage(message)

			} catch: { error, _ in
				loggerGlobal.error("Failed to send message to Connector Extension, error: \(error)")
			}

		case let .selectedLink(link):
			state.selectedLink = link
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .loadLinksResult(linksFromProfile):
			state.links = .init(
				uniqueElements: linksFromProfile
			)
			return .none
		}
	}

	private func handleIncommingRequests() -> EffectTask<Action> {
		//        .run { send in
		//            await radixConnectClient.loadFromProfileAndConnectAll()
//
		//            for try await incomingMessageResult in await radixConnectClient.receiveMessages() {
		//                guard !Task.isCancelled else {
		//                    return
		//                }
//
		//                incomingMessageResult.
		//        } catch: { error, _ in
		//            errorQueue.schedule(error)
		//        }
		.none
	}
}
