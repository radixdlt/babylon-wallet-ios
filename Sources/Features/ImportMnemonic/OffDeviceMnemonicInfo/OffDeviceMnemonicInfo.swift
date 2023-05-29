import FeaturePrelude

// MARK: - OffDeviceMnemonicInfo
public struct OffDeviceMnemonicInfo: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public let mnemonicWithPassphrase: MnemonicWithPassphrase
		public var story: String = ""
		public var backup: String = ""
		public init(mnemonicWithPassphrase: MnemonicWithPassphrase) {
			self.mnemonicWithPassphrase = mnemonicWithPassphrase
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
		case storyChanged(String)
		case backupChanged(String)
		case skipButtonTapped
		case saveButtonTapped
	}

	public enum DelegateAction: Sendable, Equatable {
		case done(
			label: FactorSource.Label,
			description: FactorSource.Description,
			MnemonicWithPassphrase
		)
	}

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return .none

		case let .storyChanged(story):
			state.story = story
			return .none

		case let .backupChanged(backup):
			state.backup = backup
			return .none

		case .skipButtonTapped, .saveButtonTapped:
			return .send(.delegate(
				.done(
					label: .init(state.story),
					description: .init(state.backup),
					state.mnemonicWithPassphrase
				))
			)
		}
	}
}
