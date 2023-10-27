import ComposableArchitecture
import SwiftUI

// MARK: - DisplayEntitiesControlledByMnemonic
public struct DisplayEntitiesControlledByMnemonic: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable, Identifiable {
		public typealias ID = EntitiesControlledByFactorSource.ID
		public var id: ID { accountsForDeviceFactorSource.id }

		public var deviceFactorSource: DeviceFactorSource { accountsForDeviceFactorSource.deviceFactorSource }

		public var accountsForDeviceFactorSource: EntitiesControlledByFactorSource

		// Mutable since if we just imported a missing mnemonic we wanna change to `mnemonicCanBeDisplayed`
		public var mode: Mode

		public enum Mode: Sendable, Hashable {
			case mnemonicCanBeDisplayed
			case mnemonicNeedsImport
			case displayAccountListOnly
		}

		public init(
			accountsForDeviceFactorSource: EntitiesControlledByFactorSource,
			mode: Mode
		) {
			self.accountsForDeviceFactorSource = accountsForDeviceFactorSource
			self.mode = mode
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
		case importMnemonicTapped
		case displayMnemonicTapped
	}

	public enum DelegateAction: Sendable, Equatable {
		case displayMnemonic
		case importMissingMnemonic
	}

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .appeared:
			.none
		case .displayMnemonicTapped:
			.send(.delegate(.displayMnemonic))
		case .importMnemonicTapped:
			.send(.delegate(.importMissingMnemonic))
		}
	}
}
