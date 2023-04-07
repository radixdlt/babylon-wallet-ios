import AccountsClient // OlympiaAccountToMigrate
import Cryptography
import EngineToolkitClient
import FeaturePrelude
import ImportLegacyWalletClient
import ScanQRFeature

// MARK: - ScanMultipleOlympiaQRCodes
public struct ScanMultipleOlympiaQRCodes: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public enum Step: Sendable, Hashable {
			case scanQR(ScanQRCoordinator.State)

			public init() {
				self = .scanQR(.init(scanInstructions: L10n.ImportLegacyWallet.ScanQRCodes.scanInstructions))
			}
		}

		public var step: Step
		public var scannedQRCodes: OrderedSet<String>

		public init(
			step: Step = .init(),
			scannedQRCodes: OrderedSet<String> = .init()
		) {
			self.step = step
			self.scannedQRCodes = scannedQRCodes
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
	}

	public enum ChildAction: Sendable, Equatable {
		case scanQR(ScanQRCoordinator.Action)
	}

	public enum InternalAction: Sendable, Equatable {
		case scannedParsedOlympiaWalletToMigrate(ScannedParsedOlympiaWalletToMigrate)
	}

	public enum DelegateAction: Sendable, Equatable {
		case finishedScanning(ScannedParsedOlympiaWalletToMigrate)
	}

	@Dependency(\.importLegacyWalletClient) var importLegacyWalletClient
	@Dependency(\.errorQueue) var errorQueue

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Scope(state: \.step, action: /Action.self) {
			EmptyReducer()
				.ifCaseLet(/State.Step.scanQR, action: /Action.child .. ChildAction.scanQR) {
					ScanQRCoordinator()
				}
		}

		Reduce(core)
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .scanQR(.delegate(.scanned(qrString))):
			do {
				let parsedScannedHeader = try importLegacyWalletClient.parseHeaderFromQRCode(qrString)
				state.scannedQRCodes.append(qrString)
				if state.scannedQRCodes.count >= parsedScannedHeader.payloadCount {
					let olympiaWallet = try importLegacyWalletClient.parseLegacyWalletFromQRCodes(state.scannedQRCodes)
					return .send(.internal(.scannedParsedOlympiaWalletToMigrate(olympiaWallet)))
				}
			} catch {
				errorQueue.schedule(error)
			}
			return .none
		default:
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .scannedParsedOlympiaWalletToMigrate(olympiaWallet):
			return .send(.delegate(.finishedScanning(olympiaWallet)))
		}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return .none
		}
	}
}
