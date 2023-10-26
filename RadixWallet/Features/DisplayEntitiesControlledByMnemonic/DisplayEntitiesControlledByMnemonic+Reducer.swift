import ComposableArchitecture
import SwiftUI

// MARK: - DisplayEntitiesControlledByMnemonic
public struct DisplayEntitiesControlledByMnemonic: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable, Identifiable {
		public typealias ID = EntitiesControlledByFactorSource.ID
		public var id: ID { accountsForDeviceFactorSource.id }

		public var deviceFactorSource: DeviceFactorSource { accountsForDeviceFactorSource.deviceFactorSource }

		public let accountsForDeviceFactorSource: EntitiesControlledByFactorSource
		public var displayRevealMnemonicLink: Bool {
			switch mode {
			case .mnemonicCanBeDisplayed: true
			case .mnemonicIsMissingNeedsImport: false
			case .displayAccountListOnly: false
			}
		}

		public var mnemonicIsMissingNeedsImport: Bool {
			switch mode {
			case .mnemonicCanBeDisplayed: false
			case .mnemonicIsMissingNeedsImport: true
			case .displayAccountListOnly: false
			}
		}

		public let mode: Mode
		public enum Mode: Sendable, Hashable {
			case mnemonicCanBeDisplayed
			case mnemonicIsMissingNeedsImport
			case displayAccountListOnly
		}

		public init(
			accountsForDeviceFactorSource: EntitiesControlledByFactorSource,
			mode: Mode? = nil
		) {
			let mode = mode ?? (accountsForDeviceFactorSource.isMnemonicPresentInKeychain ? .mnemonicCanBeDisplayed : .mnemonicIsMissingNeedsImport)
			if mode == .mnemonicCanBeDisplayed, !accountsForDeviceFactorSource.isMnemonicPresentInKeychain {
				preconditionFailure("Cannot reveal mnemonic since it is missing")
			}
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
			.none
		case .navigateButtonTapped:
			if state.mnemonicIsMissingNeedsImport {
				.send(.delegate(.importMissingMnemonic))
			} else {
				.send(.delegate(.displayMnemonic))
			}
		}
	}
}
