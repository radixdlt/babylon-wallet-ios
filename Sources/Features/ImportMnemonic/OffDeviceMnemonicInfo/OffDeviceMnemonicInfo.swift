import FeaturePrelude
import Profile

// MARK: - OffDeviceMnemonicInfo
public struct OffDeviceMnemonicInfo: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public let mnemonicWithPassphrase: MnemonicWithPassphrase
		public var label: String = ""

		public init(mnemonicWithPassphrase: MnemonicWithPassphrase) {
			self.mnemonicWithPassphrase = mnemonicWithPassphrase
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case labelChanged(String)
		case saveButtonTapped
	}

	public enum DelegateAction: Sendable, Equatable {
		case done(
			label: OffDeviceMnemonicFactorSource.Hint.Label,
			MnemonicWithPassphrase
		)
	}

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case let .labelChanged(label):
			state.label = label
			return .none

		case .saveButtonTapped:
			return .send(.delegate(
				.done(
					label: .init(state.label),
					state.mnemonicWithPassphrase
				)
			))
		}
	}
}
