import Cryptography
import FactorSourcesClient
import FeaturePrelude
import LedgerHardwareWalletClient
import NewConnectionFeature
import Profile
import RadixConnectClient
import SharedModels

// MARK: - AddLedgerFactorSource
public struct AddLedgerFactorSource: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var isConnectedToAnyCE = false
		public var ledgerName = ""
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
		case isConnectedToAnyConnectorExtension(Bool)
		case getDeviceInfoResult(
			TaskResult<P2P.ConnectorExtension.Response.LedgerHardwareWallet.Success.GetDeviceInfo>
		)

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
	@Dependency(\.ledgerHardwareWalletClient) var ledgerHardwareClient

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
				for try await isConnected in await ledgerHardwareClient.isConnectedToAnyConnectorExtension() {
					guard !Task.isCancelled else {
						return
					}
					await send(.internal(.isConnectedToAnyConnectorExtension(isConnected)))
				}
			} catch: { error, _ in
				loggerGlobal.error("failed to get links updates, error: \(error)")
			}

		case .addNewP2PLinkButtonTapped:
			state.addNewP2PLink = .init()
			return .none

		case .sendAddLedgerRequestButtonTapped:
			state.isWaitingForResponseFromLedger = true
			return .run { send in
				await send(.internal(.getDeviceInfoResult(TaskResult {
					try await ledgerHardwareClient.getDeviceInfo()
				})))
			}

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
		case let .isConnectedToAnyConnectorExtension(isConnectedToAnyCE):
			loggerGlobal.notice("Is connected to any CE?: \(isConnectedToAnyCE)")
			state.isConnectedToAnyCE = isConnectedToAnyCE
			return .none

		case let .getDeviceInfoResult(.success(ledgerDeviceInfo)):
			state.isWaitingForResponseFromLedger = false
			loggerGlobal.notice("Successfully received response from CE! \(ledgerDeviceInfo) ✅")
			state.unnamedDeviceToAdd = ledgerDeviceInfo
			return .none

		case let .getDeviceInfoResult(.failure(error)):
			state.isWaitingForResponseFromLedger = false
			loggerGlobal.error("Failed to get ledger device info: \(error)")
			errorQueue.schedule(error)
			return .none

		case .saveNewConnection:
			state.isConnectedToAnyCE = true
			return .none

		case let .addedFactorSource(factorSource, _, _):
			return .send(.delegate(.completed(ledger: factorSource)))
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
			name: name,
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
