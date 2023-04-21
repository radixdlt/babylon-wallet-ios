import Cryptography
import FactorSourcesClient
import FeaturePrelude
import NewConnectionFeature
import Profile
import RadixConnectClient
import RadixConnectModels
import SharedModels

// MARK: - AddLedgerFactorSource
public struct AddLedgerFactorSource: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var failedToFindAnyLinks = false
		public var ledgerName = ""
		public var isLedgerNameInputVisible = false
		public var isWaitingForResponseFromLedger = false
		public var unnamedDeviceToAdd: P2P.ConnectorExtension.Response.LedgerHardwareWallet.Success.GetDeviceInfo?

		@PresentationState
		public var addNewP2PLink: NewConnection.State?

		public init() {}
	}

	public enum ViewAction: Sendable, Equatable {
		case task
		case addNewP2PLinkButtonTapped
		case sendAddLedgerRequestButtonTapped
		case ledgerNameChanged(String)
		case confirmNameButtonTapped
		case skipNamingLedgerButtonTapped
	}

	public enum InternalAction: Sendable, Equatable {
		case gotLinksConnectionStatusUpdate([P2P.LinkConnectionUpdate])
		case response(
			ledgerDeviceInfo: P2P.ConnectorExtension.Response.LedgerHardwareWallet.Success.GetDeviceInfo,
			interactionID: P2P.LedgerHardwareWallet.InteractionId
		)
		case broadcasted(interactionID: P2P.LedgerHardwareWallet.InteractionId)

		case addedFactorSource(FactorSource, FactorSource.LedgerHardwareWallet.DeviceModel, name: String?)
		case saveNewConnection(P2PLink)
	}

	public enum ChildAction: Sendable, Equatable {
		case addNewP2PLink(PresentationAction<NewConnection.Action>)
	}

	public enum DelegateAction: Sendable, Equatable {
		case completed(
			ledger: FactorSource
		)
	}

	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.radixConnectClient) var radixConnectClient
	@Dependency(\.factorSourcesClient) var factorSourcesClient

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.ifLet(\.$addNewP2PLink, action: /Action.child .. ChildAction.addNewP2PLink) {
				NewConnection()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .task:

			return .run { send in
				for try await linksConnectionUpdate in await radixConnectClient.getP2PLinksWithConnectionStatusUpdates() {
					guard !Task.isCancelled else {
						return
					}
					await send(.internal(.gotLinksConnectionStatusUpdate(linksConnectionUpdate)))
				}
			} catch: { error, _ in
				loggerGlobal.error("failed to get links updates, error: \(error)")
			}

		case .addNewP2PLinkButtonTapped:
			state.addNewP2PLink = .init()
			return .none

		case .sendAddLedgerRequestButtonTapped:
			let interactionId: P2P.LedgerHardwareWallet.InteractionId = .random()
			return getDeviceInfoOfAnyConnectedLedger(
				interactionID: interactionId
			).concatenate(with: listenForResponses(interactionID: interactionId))

		case let .ledgerNameChanged(name):
			state.ledgerName = name
			return .none

		case .confirmNameButtonTapped:
			let name = state.ledgerName
			loggerGlobal.notice("Confirmed ledger name: '\(name)' => adding factor source")
			guard let device = state.unnamedDeviceToAdd else {
				assertionFailure("Expected device to name")
				return .none
			}
			return addFactorSource(
				name: name,
				unnamedDeviceToAdd: device
			)

		case .skipNamingLedgerButtonTapped:
			guard let device = state.unnamedDeviceToAdd else {
				assertionFailure("Expected device to name")
				return .none
			}
			return addFactorSource(
				name: nil,
				unnamedDeviceToAdd: device
			)
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .addNewP2PLink(.presented(.delegate(.newConnection(connectedClient)))):

			state.addNewP2PLink = nil
			return .run { send in
				try await radixConnectClient.storeP2PLink(
					connectedClient
				)
				await send(.internal(.saveNewConnection(connectedClient)))
			} catch: { error, _ in
				loggerGlobal.error("Failed P2PLink, error \(error)")
				errorQueue.schedule(error)
			}
		case .addNewP2PLink(.presented(.delegate(.dismiss))):
			state.addNewP2PLink = nil
			return .none

		default:
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .gotLinksConnectionStatusUpdate(linksConnectionStatusUpdate):
			loggerGlobal.notice("links connection status update: \(linksConnectionStatusUpdate)")
			let connectedLinks = linksConnectionStatusUpdate.filter(\.hasAnyConnectedPeers)
			state.failedToFindAnyLinks = connectedLinks.isEmpty
			return .none

		case let .response(ledgerDeviceInfo, _):
			loggerGlobal.notice("Successfully received response from CE! \(ledgerDeviceInfo) ✅")
			state.unnamedDeviceToAdd = ledgerDeviceInfo
			state.isLedgerNameInputVisible = true
			return .none

		case .saveNewConnection:
			state.failedToFindAnyLinks = false
			return .none

		case .broadcasted:
			state.isWaitingForResponseFromLedger = true
			return .none

		case let .addedFactorSource(factorSource, _, _):
			return .send(.delegate(.completed(ledger: factorSource)))
		}
	}

	private func getDeviceInfoOfAnyConnectedLedger(
		interactionID: P2P.LedgerHardwareWallet.InteractionId
	) -> EffectTask<Action> {
		.run { send in

			loggerGlobal.debug("About to broadcast getDeviceInfo request with interactionID: \(interactionID)..")

			try await radixConnectClient.sendRequest(.connectorExtension(.ledgerHardwareWallet(.init(
				interactionID: interactionID,
				request: .getDeviceInfo
			))), .broadcastToAllPeers)

			loggerGlobal.debug("Broadcasted getDeviceInfo request with interactionID: \(interactionID) ✅ waiting for response")

			await send(.internal(.broadcasted(interactionID: interactionID)))
		} catch: { error, _ in
			loggerGlobal.error("Failed to send message to Connector Extension, error: \(error)")
		}
	}

	private func listenForResponses(
		interactionID: P2P.LedgerHardwareWallet.InteractionId
	) -> EffectTask<Action> {
		.run { send in
			for try await incomingResponse in await radixConnectClient.receiveResponses(/P2P.RTCMessageFromPeer.Response.connectorExtension .. /P2P.ConnectorExtension.Response.ledgerHardwareWallet) {
				loggerGlobal.notice("Received response from CE: \(String(describing: incomingResponse))")
				guard !Task.isCancelled else {
					return
				}

				let response = try incomingResponse.result.get()

				switch response.response {
				case let .success(.getDeviceInfo(ledgerDeviceInfo)):
					await send(.internal(
						.response(
							ledgerDeviceInfo: ledgerDeviceInfo,
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
			loggerGlobal.error("Fail interactionID: \(interactionID), error: \(error)")
		}
	}

	private func addFactorSource(
		name: String?,
		unnamedDeviceToAdd device: P2P.ConnectorExtension.Response.LedgerHardwareWallet.Success.GetDeviceInfo
	) -> EffectTask<Action> {
		let model = FactorSource.LedgerHardwareWallet.DeviceModel(model: device.model)

		loggerGlobal.notice("Creating factor source for Ledger...")

		let factorSource = FactorSource.ledger(
			id: device.id,
			model: model,
			label: .init(name ?? "Unnamed"),
			olympiaCompatible: false
		)

		loggerGlobal.notice("Created factor source for Ledger! adding it now")

		return .run { send in
			try await factorSourcesClient.addOffDeviceFactorSource(factorSource)
			loggerGlobal.notice("Added Ledger factor source! ✅ ")
			await send(.internal(.addedFactorSource(factorSource, model, name: name)))
		} catch: { error, _ in
			loggerGlobal.error("Failed to add Factor Source, error: \(error)")
			errorQueue.schedule(error)
		}
	}
}

extension FactorSource.LedgerHardwareWallet.DeviceModel {
	init(model: P2P.LedgerHardwareWallet.Model) {
		switch model {
		case .nanoS: self = .nanoS
		case .nanoX: self = .nanoX
		case .nanoSPlus: self = .nanoSPlus
		}
	}
}
