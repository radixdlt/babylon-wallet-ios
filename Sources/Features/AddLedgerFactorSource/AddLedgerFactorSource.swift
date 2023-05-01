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

//		@PresentationState
//		public var addNewP2PLink: NewConnection.State?

		@PresentationState
		var destination: Destinations.State? = nil

		public init() {}
	}

	public enum ViewAction: Sendable, Equatable {
		case task
		case addNewP2PLinkButtonTapped
		case sendAddLedgerRequestButtonTapped
		case ledgerNameChanged(String)
		case confirmNameButtonTapped
		case skipNamingLedgerButtonTapped

		public enum CloseLedgerAlreadyExistsDialogAction: Sendable, Hashable {
			case tryAnotherLedger
			case finish
		}
	}

	public enum InternalAction: Sendable, Equatable {
		case isConnectedToAnyConnectorExtension(Bool)
		case getDeviceInfoResult(
			TaskResult<P2P.ConnectorExtension.Response.LedgerHardwareWallet.Success.GetDeviceInfo>
		)
		case alreadyExists(P2P.ConnectorExtension.Response.LedgerHardwareWallet.Success.GetDeviceInfo, FactorSource)
		case nameLedgerBeforeAddingIt(P2P.ConnectorExtension.Response.LedgerHardwareWallet.Success.GetDeviceInfo)
		case addedFactorSource(FactorSource, FactorSource.LedgerHardwareWallet.DeviceModel, name: String?)
		case saveNewConnection(P2PLink)
	}

	public enum ChildAction: Sendable, Equatable {
//		case addNewP2PLink(PresentationAction<NewConnection.Action>)
		case destination(PresentationAction<Destinations.Action>)
	}

	public enum DelegateAction: Sendable, Equatable {
		case completed(
			ledger: FactorSource
		)
	}

	public struct Destinations: Sendable, ReducerProtocol {
		public enum State: Sendable, Hashable {
			case addNewP2PLink(NewConnection.State)
			case closeLedgerAlreadyExistsConfirmationDialog(ConfirmationDialogState<ViewAction.CloseLedgerAlreadyExistsDialogAction>)
		}

		public enum Action: Sendable, Equatable {
			case addNewP2PLink(NewConnection.Action)
			case closeLedgerAlreadyExistsConfirmationDialog(ViewAction.CloseLedgerAlreadyExistsDialogAction)
		}

		public var body: some ReducerProtocolOf<Self> {
			Scope(state: /State.addNewP2PLink, action: /Action.addNewP2PLink) {
				NewConnection()
			}
		}
	}

	@Dependency(\.dismiss) var dismiss
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.radixConnectClient) var radixConnectClient
	@Dependency(\.factorSourcesClient) var factorSourcesClient
	@Dependency(\.ledgerHardwareWalletClient) var ledgerHardwareClient

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.ifLet(\.$destination, action: /Action.child .. ChildAction.destination) {
				Destinations()
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
//			state.addNewP2PLink = .init()
			state.destination = .addNewP2PLink(.init())
			return .none

		case .sendAddLedgerRequestButtonTapped:
			return sendAddLedgerRequest(&state)

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
		case let .destination(.presented(.addNewP2PLink(.delegate(.newConnection(connectedClient))))):

			state.destination = nil
			return .run { send in
				try await radixConnectClient.storeP2PLink(
					connectedClient
				)
				await send(.internal(.saveNewConnection(connectedClient)))
			} catch: { error, _ in
				loggerGlobal.error("Failed P2PLink, error \(error)")
				errorQueue.schedule(error)
			}
		case .destination(.presented(.addNewP2PLink(.delegate(.dismiss)))):
//			state.addNewP2PLink = nil
			state.destination = nil
			return .none

		case .destination(.presented(.closeLedgerAlreadyExistsConfirmationDialog(.finish))):
			return .fireAndForget { await dismiss() }

		case .destination(.presented(.closeLedgerAlreadyExistsConfirmationDialog(.tryAnotherLedger))):
			return sendAddLedgerRequest(&state)

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
			return .run { send in
				let allFactorSources = try await factorSourcesClient.getFactorSources()
				if let existing = allFactorSources.first(where: { $0.id == ledgerDeviceInfo.id }) {
					await send(.internal(.alreadyExists(ledgerDeviceInfo, existing)))
				} else {
					// new!
					await send(.internal(.nameLedgerBeforeAddingIt(
						ledgerDeviceInfo
					)))
				}
			} catch: { _, send in
				await send(.internal(.nameLedgerBeforeAddingIt(ledgerDeviceInfo)))
			}

		case let .alreadyExists(deviceFromConnectorExtension, existingFactorSource):

			state.destination = .closeLedgerAlreadyExistsConfirmationDialog(
				.init(titleVisibility: .hidden) {
					TextState("")
				} actions: {
					ButtonState(role: .destructive, action: .send(.finish)) {
						TextState("Finish adding ledgers..")
					}
					ButtonState(role: .cancel, action: .send(.tryAnotherLedger)) {
						TextState("Connect a different Ledger to computer")
					}
				} message: {
					TextState("You have already added this ledger \(existingFactorSource.label.rawValue) \(existingFactorSource.description.rawValue) on \(existingFactorSource.addedOn.ISO8601Format())")
				}
			)
			return .none

		case let .nameLedgerBeforeAddingIt(unnamedDevice):
			state.unnamedDeviceToAdd = unnamedDevice
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

	private func sendAddLedgerRequest(_ state: inout State) -> EffectTask<Action> {
		state.isWaitingForResponseFromLedger = true
		return .run { send in
			await send(.internal(.getDeviceInfoResult(TaskResult {
				try await ledgerHardwareClient.getDeviceInfo()
			})))
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
