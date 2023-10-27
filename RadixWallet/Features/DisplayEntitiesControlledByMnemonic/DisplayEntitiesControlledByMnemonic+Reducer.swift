import ComposableArchitecture
import SwiftUI

// MARK: - DisplayEntitiesControlledByMnemonic
public struct DisplayEntitiesControlledByMnemonic: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable, Identifiable {
		public typealias ID = EntitiesControlledByFactorSource.ID
		public var id: ID { accountsForDeviceFactorSource.id }

		public var deviceFactorSource: DeviceFactorSource { accountsForDeviceFactorSource.deviceFactorSource }

		public var accountsForDeviceFactorSource: EntitiesControlledByFactorSource
		public var displayRevealMnemonicLink: Bool {
			switch mode {
			case .mnemonicCanBeDisplayed: true
			case .mnemonicNeedsImport: false
			case .displayAccountListOnly: false
			}
		}

		public var mnemonicNeedsImport: Bool {
			switch mode {
			case .mnemonicCanBeDisplayed: false
			case .mnemonicNeedsImport: true
			case .displayAccountListOnly: false
			}
		}

		public var promptUserToBackUpMnemonic: Bool {
			get {
				!accountsForDeviceFactorSource.isMnemonicMarkedAsBackedUp
			}
			set {
				accountsForDeviceFactorSource.isMnemonicMarkedAsBackedUp = !newValue
			}
		}

		// Mutable since if we just imported a missing mnemonic we wanna change to `mnemonicCanBeDisplayed`
		public var mode: Mode

		public enum Mode: Sendable, Hashable {
			case mnemonicCanBeDisplayed
			case mnemonicNeedsImport
			case displayAccountListOnly
		}

		public init(
			accountsForDeviceFactorSource: EntitiesControlledByFactorSource,
			mode: Mode? = nil
		) {
			let mode = mode ?? (accountsForDeviceFactorSource.isMnemonicPresentInKeychain ? .mnemonicCanBeDisplayed : .mnemonicNeedsImport)
			if mode == .mnemonicCanBeDisplayed, !accountsForDeviceFactorSource.isMnemonicPresentInKeychain {
				preconditionFailure("Cannot reveal mnemonic since it is missing")
			}
			self.accountsForDeviceFactorSource = accountsForDeviceFactorSource
			self.mode = mode
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
		case importMnemonic
		case displayMnemonic
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
		case .displayMnemonic:
			.send(.delegate(.displayMnemonic))
		case .importMnemonic:
			.send(.delegate(.importMissingMnemonic))
		}
	}
}
