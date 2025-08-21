import ComposableArchitecture
import SwiftUI

// MARK: - DisplayEntitiesControlledByMnemonic
struct DisplayEntitiesControlledByMnemonic: Sendable, FeatureReducer {
	struct State: Sendable, Hashable, Identifiable {
		enum ID: Sendable, Hashable {
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

			var factorSourceID: FactorSourceIDFromHash {
				switch self {
				case let .mixedCurves(id): id
				case let .singleCurve(id, _): id
				}
			}
		}

		let id: ID

		var isMnemonicMarkedAsBackedUp: Bool
		var isMnemonicPresentInKeychain: Bool
		let accounts: IdentifiedArrayOf<Account>
		let hiddenAccountsCount: Int
		let personasCount: Int
		var mode: Mode

		enum Mode: Sendable, Hashable {
			case mnemonicCanBeDisplayed
			case mnemonicNeedsImport
			case displayAccountListOnly
		}

		init(
			id: ID,
			isMnemonicMarkedAsBackedUp: Bool,
			isMnemonicPresentInKeychain: Bool,
			accounts: IdentifiedArrayOf<Account>,
			hiddenAccountsCount: Int,
			personasCount: Int,
			mode: Mode
		) {
			self.id = id
			self.isMnemonicMarkedAsBackedUp = isMnemonicMarkedAsBackedUp
			self.isMnemonicPresentInKeychain = isMnemonicPresentInKeychain
			self.accounts = accounts
			self.hiddenAccountsCount = hiddenAccountsCount
			self.personasCount = personasCount
			self.mode = mode
		}

		init(
			entitiesControlledByKeysOnSameCurve entitiesSet: EntitiesControlledByFactorSource.EntitiesControlledByKeysOnSameCurve,
			problems: [SecurityProblem]
		) {
			let accounts = entitiesSet.accounts.elements + entitiesSet.hiddenAccounts.elements
			let isMnemonicMarkedAsBackedUp = !problems.hasProblem3(accounts: accounts, personas: entitiesSet.personas)
			let isMnemonicPresentInKeychain = !problems.hasProblem9(accounts: accounts, personas: entitiesSet.personas)
			self.init(
				id: .singleCurve(entitiesSet.id.factorSourceID, isOlympia: entitiesSet.id.isOlympia),
				isMnemonicMarkedAsBackedUp: isMnemonicMarkedAsBackedUp,
				isMnemonicPresentInKeychain: isMnemonicPresentInKeychain,
				accounts: entitiesSet.accounts,
				hiddenAccountsCount: entitiesSet.hiddenAccounts.count,
				personasCount: entitiesSet.personas.count,
				mode: isMnemonicPresentInKeychain ? .mnemonicCanBeDisplayed : .mnemonicNeedsImport
			)
		}
	}

	enum ViewAction: Sendable, Equatable {
		case appeared
		case navigateButtonTapped
	}

	enum DelegateAction: Sendable, Equatable {
		case displayMnemonic
		case importMissingMnemonic
	}

	init() {}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
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

extension [SecurityProblem] {
	/// Returns if the given collection of `SecurityProblem` has any `.problem3` for at least one of the entities provided
	func hasProblem3(accounts: [Account], personas: [Persona]) -> Bool {
		contains { problem in
			switch problem {
			case let .problem3(addresses):
				!addresses.problematicAccounts.isDisjoint(with: accounts.map(\.address)) ||
					!Set(addresses.personas).isDisjoint(with: personas.map(\.address))
			default:
				false
			}
		}
	}

	/// Returns if the given collection of `SecurityProblem` has any `.problem9` for at least one of the entities provided
	func hasProblem9(accounts: [Account], personas: [Persona]) -> Bool {
		contains { problem in
			switch problem {
			case let .problem9(addresses):
				!addresses.problematicAccounts.isDisjoint(with: accounts.map(\.address)) ||
					!Set(addresses.personas).isDisjoint(with: personas.map(\.address))
			default:
				false
			}
		}
	}

	func hasProblem9() -> Bool {
		contains { problem in
			switch problem {
			case .problem9:
				true
			default:
				false
			}
		}
	}

	func hasProblem3() -> Bool {
		contains { problem in
			switch problem {
			case .problem3:
				true
			default:
				false
			}
		}
	}
}

private extension AddressesOfEntitiesInBadState {
	var problematicAccounts: Set<AccountAddress> {
		Set(accounts + hiddenAccounts)
	}
}
