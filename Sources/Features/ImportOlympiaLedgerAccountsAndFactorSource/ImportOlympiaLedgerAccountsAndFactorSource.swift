import FactorSourcesClient
import FeaturePrelude
import RadixConnectClient

// MARK: - ImportOlympiaLedgerAccountsAndFactorSource
public struct ImportOlympiaLedgerAccountsAndFactorSource: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var outgoingInteractionIDs: Set<P2P.LedgerHardwareWallet.InteractionId>?
		public var verified: Set<OlympiaAccountToMigrate> = .init()
		public var unverified: Set<OlympiaAccountToMigrate>
		public init(
			hardwareAccounts: NonEmpty<OrderedSet<OlympiaAccountToMigrate>>
		) {
			precondition(hardwareAccounts.allSatisfy { $0.accountType == .hardware })
			self.unverified = Set(hardwareAccounts.elements)
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
		case sendAddLedgerRequestButtonTapped
	}

	public enum InternalAction: Sendable, Equatable {
		case response(
			olympiaDevice: P2P.ConnectorExtension.Response.LedgerHardwareWallet.Success.ImportOlympiaDevice,
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
		case .appeared:
			return .fireAndForget {
				await radixConnectClient.loadFromProfileAndConnectAll()
			}
		case .sendAddLedgerRequestButtonTapped:
			let interactionId: P2P.LedgerHardwareWallet.InteractionId = .random()
			return importOlympiaDevice(
				interactionID: interactionId,
				olympiaHardwareAccounts: state.unverified
			).concatenate(with: listenForResponses(interactionID: interactionId))
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .response(olympiaDevice, interactionID):
			return .none
		case let .broadcasted(interactionID):
			return .none
		}
	}

	private func listenForResponses(
		interactionID: P2P.LedgerHardwareWallet.InteractionId
	) -> EffectTask<Action> {
		.run { send in
			for try await incomingResponse in await radixConnectClient.receiveResponses(/P2P.RTCMessageFromPeer.Response.connectorExtension .. /P2P.ConnectorExtension.Response.ledgerHardwareWallet) {
				guard !Task.isCancelled else {
					return
				}

				let response = try incomingResponse.result.get()

				switch response.response {
				case let .success(.importOlympiaDevice(olympiaDevice)):
					await send(.internal(
						.response(
							olympiaDevice: olympiaDevice,
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
			//            await send(.internal(.failure(interactionID: interactionID)))
			loggerGlobal.error("Fail interactionID: \(interactionID), error: \(error)")
		}
	}

	private func importOlympiaDevice(
		interactionID: P2P.LedgerHardwareWallet.InteractionId,
		olympiaHardwareAccounts: Set<OlympiaAccountToMigrate>
	) -> EffectTask<Action> {
		.run { send in

			let request: P2P.ConnectorExtension.Request.LedgerHardwareWallet.Request.ImportOlympiaDevice = .init(
				derivationPaths: olympiaHardwareAccounts.map(\.path.derivationPath)
			)

			try await radixConnectClient.sendRequest(.connectorExtension(.ledgerHardwareWallet(.init(
				interactionID: interactionID,
				request: .importOlympiaDevice(request)
			))), .broadcastToAllPeers)

			await send(.internal(.broadcasted(interactionID: interactionID)))
		} catch: { error, _ in
			loggerGlobal.error("Failed to send message to Connector Extension, error: \(error)")
		}
	}
}
