import FeaturePrelude
import ScanQRFeature

// MARK: - ImportFromOlympiaLegacyWallet
public struct ImportFromOlympiaLegacyWallet: Sendable, FeatureReducer {
	public enum State: Sendable, Hashable {
		case scanQR(ScanQR.State)

		public init() {
			self = .scanQR(.init())
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
	}

	public enum ChildAction: Sendable, Equatable {
		case scanQR(ScanQR.Action)
	}

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.ifCaseLet(/State.scanQR, action: /Action.child .. ChildAction.scanQR) {
				ScanQR()
			}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .scanQR(.delegate(.scanned(qrString))):
			return .run { _ in
				fatalError()
			}

		default:
			return .none
		}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return .none
		}
	}
}
