import ComposableArchitecture
import SwiftUI

// MARK: - DisplayEntitiesControlledByMnemonic
public struct DisplayEntitiesControlledByMnemonic: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable, Identifiable {
		public typealias ID = FactorSource.ID.FromHash
		public let id: ID

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
			self.id = accountsForDeviceFactorSource.factorSourceID
			self.accountsForDeviceFactorSource = accountsForDeviceFactorSource
			self.mode = mode
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
		case navigateButtonTapped
	}

	public enum DelegateAction: Sendable, Equatable {
		case displayMnemonic
		case importMissingMnemonic
	}

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .appeared:
			return .none
		case .navigateButtonTapped:
			switch state.mode {
			case .mnemonicCanBeDisplayed:
				return .send(.delegate(.displayMnemonic))
			case .mnemonicNeedsImport:
				return .send(.delegate(.importMissingMnemonic))
			case .displayAccountListOnly:
				assertionFailure("not clickable")
				return .none
			}
		}
	}
}
