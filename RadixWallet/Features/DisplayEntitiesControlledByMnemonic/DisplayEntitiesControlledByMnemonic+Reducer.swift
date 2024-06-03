import ComposableArchitecture
import SwiftUI

// MARK: - DisplayEntitiesControlledByMnemonic
public struct DisplayEntitiesControlledByMnemonic: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable, Identifiable {
		public enum ID: Sendable, Hashable {
			/// Mixture of account sets, including both:
			/// * "Babylon accounts" (controlled by keys on `Curve25519`)
			/// * "Olympia accounts" (controlled by keys on curve `secp256k1`)
			case mixedCurves(FactorSourceIDFromHash)

			/// Only of accounts in one of the sets:
			/// - "Babylon accounts" (controlled by keys on `Curve25519`)
			///
			/// **OR**
			///
			/// - "Olympia accounts" (controlled by keys on curve `secp256k1`)
			case singleCurve(FactorSourceIDFromHash, isOlympia: Bool)

			public var factorSourceID: FactorSourceIDFromHash {
				switch self {
				case let .mixedCurves(id): id
				case let .singleCurve(id, _): id
				}
			}
		}

		public let id: ID

		public var isMnemonicMarkedAsBackedUp: Bool
		public var isMnemonicPresentInKeychain: Bool
		public let accounts: IdentifiedArrayOf<Account>
		public let hiddenAccountsCount: Int
		public var mode: Mode

		public enum Mode: Sendable, Hashable {
			case mnemonicCanBeDisplayed
			case mnemonicNeedsImport
			case displayAccountListOnly
		}

		public init(
			id: ID,
			isMnemonicMarkedAsBackedUp: Bool,
			isMnemonicPresentInKeychain: Bool,
			accounts: IdentifiedArrayOf<Account>,
			hiddenAccountsCount: Int,
			mode: Mode
		) {
			self.id = id
			self.isMnemonicMarkedAsBackedUp = isMnemonicMarkedAsBackedUp
			self.isMnemonicPresentInKeychain = isMnemonicPresentInKeychain
			self.accounts = accounts
			self.hiddenAccountsCount = hiddenAccountsCount
			self.mode = mode
		}

		public init(
			accountsControlledByKeysOnSameCurve accountSet: EntitiesControlledByFactorSource.AccountsControlledByKeysOnSameCurve,
			problems: [SecurityProblem]
		) {
			let accounts = accountSet.accounts.elements + accountSet.hiddenAccounts.elements
			let isMnemonicMarkedAsBackedUp = problems.isMnemonicMarkedAsBackedUp(accounts: accounts)
			let isMnemonicPresentInKeychain = problems.isMnemonicPresentInKeychain(accounts: accounts)
			self.init(
				id: .singleCurve(accountSet.id.factorSourceID, isOlympia: accountSet.id.isOlympia),
				isMnemonicMarkedAsBackedUp: isMnemonicMarkedAsBackedUp,
				isMnemonicPresentInKeychain: isMnemonicPresentInKeychain,
				accounts: accountSet.accounts,
				hiddenAccountsCount: accountSet.hiddenAccounts.count,
				mode: isMnemonicPresentInKeychain ? .mnemonicCanBeDisplayed : .mnemonicNeedsImport
			)
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

private extension [SecurityProblem] {
	func isMnemonicMarkedAsBackedUp(accounts: [Account]) -> Bool {
		allSatisfy { problem in
			switch problem {
			case let .problem3(problematicAccounts, _):
				Set(problematicAccounts).isDisjoint(with: accounts.map(\.address))
			default:
				true
			}
		}
	}

	func isMnemonicPresentInKeychain(accounts: [Account]) -> Bool {
		allSatisfy { problem in
			switch problem {
			case let .problem9(problematicAccounts, _):
				Set(problematicAccounts).isDisjoint(with: accounts.map(\.address))
			default:
				true
			}
		}
	}
}
