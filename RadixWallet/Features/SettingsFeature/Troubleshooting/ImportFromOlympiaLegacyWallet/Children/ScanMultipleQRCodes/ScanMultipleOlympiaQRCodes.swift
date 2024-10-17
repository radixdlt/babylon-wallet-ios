import ComposableArchitecture
import SwiftUI

// MARK: - ScanMultipleOlympiaQRCodes
struct ScanMultipleOlympiaQRCodes: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		struct ScannedPayload: Sendable, Hashable, Identifiable {
			typealias ID = Int
			var id: ID { payloadIndex }
			let unparsedPayload: NonEmptyString
			let payloadIndex: Int
		}

		var scanQR: ScanQRCoordinator.State
		var numberOfPayloadsToScan: Int?
		var scannedPayloads: IdentifiedArrayOf<ScannedPayload>

		init(
			scannedPayloads: IdentifiedArrayOf<ScannedPayload> = []
		) {
			self.scanQR = .init(kind: .importOlympia)
			self.scannedPayloads = scannedPayloads
		}

		mutating func reset() {
			numberOfPayloadsToScan = nil
			scannedPayloads = []
		}
	}

	enum ViewAction: Sendable, Equatable {
		case appeared
	}

	enum ChildAction: Sendable, Equatable {
		case scanQR(ScanQRCoordinator.Action)
	}

	enum InternalAction: Sendable, Equatable {
		case scannedParsedOlympiaWalletToMigrate(ScannedParsedOlympiaWalletToMigrate)
	}

	enum DelegateAction: Sendable, Equatable {
		case viewAppeared
		case finishedScanning(ScannedParsedOlympiaWalletToMigrate)
	}

	@Dependency(\.importLegacyWalletClient) var importLegacyWalletClient
	@Dependency(\.dismiss) var dismiss
	@Dependency(\.errorQueue) var errorQueue

	init() {}

	var body: some ReducerOf<Self> {
		Scope(state: \.scanQR, action: /Action.child .. ChildAction.scanQR) {
			ScanQRCoordinator()
		}
		Reduce(core)
	}

	func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
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

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .scannedParsedOlympiaWalletToMigrate(olympiaWallet):
			.send(.delegate(.finishedScanning(olympiaWallet)))
		}
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .appeared:
			.send(.delegate(.viewAppeared))
		}
	}
}
