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

		public var scanQR: ScanQRCoordinator.State
		public var numberOfPayloadsToScan: Int?
		public var scannedPayloads: IdentifiedArrayOf<ScannedPayload>

		public init(
			scannedPayloads: IdentifiedArrayOf<ScannedPayload> = []
		) {
			self.scanQR = .init(scanInstructions: L10n.ImportOlympiaAccounts.ScanQR.instructions)
			self.scannedPayloads = scannedPayloads
		}

		public mutating func reset() {
			numberOfPayloadsToScan = nil
			scannedPayloads = []
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
		case viewAppeared
		case finishedScanning(ScannedParsedOlympiaWalletToMigrate)
	}

	@Dependency(\.importLegacyWalletClient) var importLegacyWalletClient
	@Dependency(\.dismiss) var dismiss
	@Dependency(\.errorQueue) var errorQueue

	public init() {}

	public var body: some ReducerOf<Self> {
		Scope(state: \.scanQR, action: /Action.child .. ChildAction.scanQR) {
			ScanQRCoordinator()
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

		case .scanQR(.delegate(.dismiss)):
			return .run { _ in
				await dismiss()
			}

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
			return .send(.delegate(.viewAppeared))
		}
	}
}
