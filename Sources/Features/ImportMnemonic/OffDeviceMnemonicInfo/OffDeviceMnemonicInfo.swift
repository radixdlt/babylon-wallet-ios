import FeaturePrelude

// MARK: - OffDeviceMnemonicInfo
public struct OffDeviceMnemonicInfo: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public let mnemonicWithPassphrase: MnemonicWithPassphrase
		public init(mnemonicWithPassphrase: MnemonicWithPassphrase) {
			self.mnemonicWithPassphrase = mnemonicWithPassphrase
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
		case storyChanged
	}

	public enum DelegateAction: Sendable, Equatable {
		case done(label: FactorSource.Label, description: FactorSource.Description, MnemonicWithPassphrase)
	}

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return .none
		}
	}
}
