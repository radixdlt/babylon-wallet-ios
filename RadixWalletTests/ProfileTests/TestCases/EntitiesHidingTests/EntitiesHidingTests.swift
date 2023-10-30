import EngineToolkit
@testable import Radix_Wallet_Dev
import XCTest

final class EntitiesHidingTests: TestCase {
	let account0 = Profile.Network.Account.testValueIdx0
	let account1 = Profile.Network.Account.testValueIdx1

	let persona0 = Profile.Network.Persona.testValueIdx0
	let persona1 = Profile.Network.Persona.testValueIdx1

	func test_hideAccount_WHEN_accountIsHidden_THEN_accountIsFilteredOut() {
		var network = Profile.Network(
			networkID: .mainnet,
			accounts: .init(rawValue: [account0, account1])!,
			personas: [],
			authorizedDapps: []
		)

		network.hideAccount(account0)

		XCTAssertEqual(network.getAccounts(), [account1])
	}

	func test_hideAccount_WHEN_accountIsHidden_THEN_accountIsReturnedInHiddenAccounts() {
		var network = Profile.Network(
			networkID: .mainnet,
			accounts: .init(rawValue: [account0, account1])!,
			personas: [],
			authorizedDapps: []
		)

		network.hideAccount(account0)

		XCTAssertEqual(network.getHiddenAccounts(), [account0])
	}

	func test_hidePersona_WHEN_personaIsHidden_THEN_personaIsFilteredOut() {
		var network = Profile.Network(
			networkID: .mainnet,
			accounts: .init(rawValue: [account0, account1])!,
			personas: [persona0, persona1],
			authorizedDapps: []
		)

		network.hidePersona(persona0)

		XCTAssertEqual(network.getPersonas(), [persona1])
	}

	func test_hidePersona_WHEN_personaIsHidden_THEN_personaIsReturnedInHiddenPersonas() {
		var network = Profile.Network(
			networkID: .mainnet,
			accounts: .init(rawValue: [account0, account1])!,
			personas: [persona0, persona1],
			authorizedDapps: []
		)

		network.hidePersona(persona0)

		XCTAssertEqual(network.getHiddenPersonas(), [persona0])
	}
}
