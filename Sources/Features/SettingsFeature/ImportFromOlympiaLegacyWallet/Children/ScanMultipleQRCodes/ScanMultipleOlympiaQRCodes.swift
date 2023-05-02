import Cryptography
import FeaturePrelude
import ImportLegacyWalletClient
import ScanQRFeature

// MARK: - ScanMultipleOlympiaQRCodes
public struct ScanMultipleOlympiaQRCodes: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public struct ScannedPayload: Sendable, Hashable, Identifiable {
			public typealias ID = Int
			public var id: ID { payloadIndex }
			public let unparsedPayload: NonEmptyString
			public let payloadIndex: Int
		}

		public enum Step: Sendable, Hashable {
			case scanQR(ScanQRCoordinator.State)

			public init() {
				self = .scanQR(.init(scanInstructions: L10n.ImportLegacyWallet.ScanQRCodes.scanInstructions))
			}
		}

		public var step: Step
		public var numberOfPayloadsToScan: Int?
		public var scannedPayloads: IdentifiedArrayOf<ScannedPayload>

		public init(
			step: Step = .init(),
			numberOfPayloadsToScan: Int? = nil,
			scannedPayloads: IdentifiedArrayOf<ScannedPayload> = []
		) {
			self.step = step
			self.numberOfPayloadsToScan = numberOfPayloadsToScan
			self.scannedPayloads = scannedPayloads
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
			guard let unparsed = NonEmptyString(qrString) else {
				return .none
			}
			do {
				let parsedScannedHeader = try importLegacyWalletClient.parseHeaderFromQRCode(unparsed)
				state.numberOfPayloadsToScan = parsedScannedHeader.payloadCount
				let scannedPayload = State.ScannedPayload(
					unparsedPayload: unparsed,
					payloadIndex: parsedScannedHeader.payloadIndex
				)

				state.scannedPayloads.append(scannedPayload)

				if state.scannedPayloads.count == parsedScannedHeader.payloadCount {
					let payloads = state.scannedPayloads.sorted(by: \.payloadIndex).map(\.unparsedPayload)

					guard
						!payloads.isEmpty,
						case let orderedSet = OrderedSet<NonEmptyString>(uncheckedUniqueElements: payloads),
						let toParse = NonEmpty(rawValue: orderedSet)
					else {
						return .none
					}

					let olympiaWallet = try importLegacyWalletClient.parseLegacyWalletFromQRCodes(toParse)

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
