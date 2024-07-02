import ComposableArchitecture
import SwiftUI

// MARK: - ScanQR
public struct ScanQR: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public let scanInstructions: String
		public let scanMode: Mode
		public let disclosure: Disclosure?
		#if targetEnvironment(simulator)
		public var manualQRContent: String

		public init(
			scanInstructions: String,
			scanMode: QRScanMode = .default,
			disclosure: Disclosure? = nil,
			manualQRContent: String = ""
		) {
			self.scanInstructions = scanInstructions
			self.scanMode = scanMode
			self.disclosure = disclosure
			self.manualQRContent = manualQRContent
		}
		#else
		public init(
			scanInstructions: String,
			scanMode: Mode = .default,
			disclosure: Disclosure? = nil
		) {
			self.scanInstructions = scanInstructions
			self.scanMode = scanMode
			self.disclosure = disclosure
		}
		#endif // sim
	}

	public enum ViewAction: Sendable, Equatable {
		case scanned(TaskResult<String>)
		#if targetEnvironment(simulator)
		case macInputQRContentChanged(String)
		case macConnectButtonTapped
		#endif // sim
	}

	public enum DelegateAction: Sendable, Equatable {
		case scanned(String)
	}

	@Dependency(\.errorQueue) var errorQueue

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		#if targetEnvironment(simulator)
		case let .macInputQRContentChanged(manualQRContent):
			state.manualQRContent = manualQRContent
			return .none

		case .macConnectButtonTapped:
			return .send(.delegate(.scanned(state.manualQRContent)))
		#endif // sim

		case let .scanned(.success(qrString)):
			return .send(.delegate(.scanned(qrString)))

		case let .scanned(.failure(error)):
			errorQueue.schedule(error)
			return .none
		}
	}
}

extension ScanQR {
	public enum Mode: Sendable, Hashable {
		/// Scan exactly one code, then stop.
		case once

		/// Scan each code no more than once.
		case oncePerCode

		/// Keep scanning all codes until dismissed.
		case continuous

		/// Scan only when capture button is tapped.
		case manual

		public static let `default`: Self = .oncePerCode
	}

	public enum Disclosure: Sendable, Hashable {
		case connector
	}
}
