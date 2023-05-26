import FeaturePrelude

// MARK: - DisplayMnemonicRow
public struct DisplayMnemonicRow: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable, Identifiable {
		public typealias ID = FactorSourceID
		public var id: ID { deviceFactorSource.id }
		public let deviceFactorSource: HDOnDeviceFactorSource
		public init(deviceFactorSource: HDOnDeviceFactorSource) {
			self.deviceFactorSource = deviceFactorSource
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
		case tapped
	}

	public enum DelegateAction: Sendable, Equatable {
		case openDetails
	}

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return .none
		case .tapped:
			return .send(.delegate(.openDetails))
		}
	}
}
