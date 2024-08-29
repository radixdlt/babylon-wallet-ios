
@testable import Radix_Wallet_Dev
import Sargon
import XCTest

// MARK: - EntitiesHidingTests
final class EntitiesHidingTests: TestCase {
	let account0 = Account.sampleMainnet
	let account1 = Account.sampleMainnetThird

	let persona0 = Persona.sampleMainnet
	let persona1 = Persona.sampleMainnetThird

	lazy var sharedPersona0 = AuthorizedPersonaSimple(
		identityAddress: persona0.address,
		lastLogin: .now,
		sharedAccounts: .init(
			request: .atLeast(
				1
			),
			ids: [
				account0,
				account1,
			].map(
				\.address
			)
		),
		sharedPersonaData: .default
	)

	lazy var sharedPersona1 = AuthorizedPersonaSimple(
		identityAddress: persona1.address,
		lastLogin: .now,
		sharedAccounts: .init(
			request: .atLeast(
				1
			),
			ids: [
				account0,
				account1,
			].map(
				\.address
			)
		),
		sharedPersonaData: .default
	)

	lazy var dApp0 = AuthorizedDapp(
		networkId: .mainnet,
		dappDefinitionAddress: .sample,
		displayName: "name 0",
		referencesToAuthorizedPersonas: [sharedPersona0],
		preferences: .init(deposits: .visible)
	)

	lazy var dApp1 = AuthorizedDapp(
		networkId: .mainnet,
		dappDefinitionAddress: .sampleOther,
		displayName: "name 1",
		referencesToAuthorizedPersonas: [sharedPersona0, sharedPersona1],
		preferences: .init(deposits: .visible)
	)

	lazy var network = ProfileNetwork(
		id: .mainnet,
		accounts: [account0, account1],
		personas: [persona0, persona1],
		authorizedDapps: [dApp0, dApp1]
	)

	func test_GIVEN_hasUnhiddenAccounts_WHEN_accountIsHidden_THEN_accountIsFilteredOut() {
		var sut = network
		sut.hide(account: account0)
		XCTAssertEqual(sut.getAccounts(), [account1])
	}

	func test_GIVEN_hasUnhiddenAccounts_WHEN_accountIsHidden_THEN_accountIsReturnedInHiddenAccounts() {
		var sut = network
		sut.hide(account: account0)
		XCTAssertEqual(sut.getHiddenAccounts().map(\.id), [account0.id])
	}

	func test_GIVEN_hasHiddenAccounts_WHEN_checkingIfUserHasSomeAccounts_THEN_returnsTrue() {
		var sut = network
		sut.hide(account: account0)
		sut.hide(account: account1)
		XCTAssertTrue(sut.hasSomeAccount())
	}

	func test_GIVEN_hasUnhiddenPersonas_WHEN_personaIsHidden_THEN_personaIsFilteredOut() {
		var sut = network
		sut.hide(persona: persona0)
		XCTAssertEqual(sut.getPersonas(), [persona1])
	}

	func test_GIVEN_hasUnhiddenPersonas_WHEN_personaIsHidden_THEN_personaIsReturnedInHiddenPersonas() {
		var sut = network
		sut.hide(persona: persona0)
		XCTAssertEqual(sut.getHiddenPersonas().map(\.id), [persona0.id])
	}

	func test_GIVEN_hasHiddenPersonas_WHEN_checkingIfUserHasSomePersonas_THEN_returnsTrue() {
		var sut = network
		sut.hide(persona: persona0)
		sut.hide(persona: persona1)
		XCTAssertTrue(sut.hasSomePersona())
	}

	func test_GIVEN_hasSharedAccountsWithDapps_WHEN_accountIsHidden_THEN_accountIsRemovedFromSharedAccounts() {
		var sut = network
		sut.hide(account: account0)

		let authorizedDapp0 = sut.authorizedDapps.asIdentified()[id: dApp0.id]!
		let authorizedDapp1 = sut.authorizedDapps.asIdentified()[id: dApp1.id]!

		/// Assert that account0 is not present anymore, but account1 is still kept.
		XCTAssertEqual(authorizedDapp0.referencesToAuthorizedPersonas.asIdentified()[id: sharedPersona0.id]?.sharedAccounts?.ids, [account1.address])
		XCTAssertEqual(authorizedDapp1.referencesToAuthorizedPersonas.asIdentified()[id: sharedPersona0.id]?.sharedAccounts?.ids, [account1.address])
		XCTAssertEqual(authorizedDapp1.referencesToAuthorizedPersonas.asIdentified()[id: sharedPersona1.id]?.sharedAccounts?.ids, [account1.address])
	}

	func test_GIVEN_hasAuthorizedDappsWithOnePersona_WHEN_personaIsHidden_THEN_dappIsRemoved() {
		var sut = network
		sut.hide(persona: persona0)

		/// dApp0 references only persona0
		XCTAssertNil(sut.authorizedDapps.asIdentified()[id: dApp0.id])
	}

	func test_GIVEN_hasAuthorizedDappsWithMoreThanOnePersona_WHEN_personaIsHidden_THEN_personaIsRemovedFromDapp() throws {
		var sut = network
		sut.hide(persona: persona0)

		/// authorizedDapp1 references persona0 and persona1
		let authorizedDapp1 = try XCTUnwrap(sut.authorizedDapps.first { $0.dAppDefinitionAddress == dApp1.dAppDefinitionAddress })

		/// Assert that persona0 is removed, but persona1 is still kept.
		XCTAssertEqual(authorizedDapp1.referencesToAuthorizedPersonas.map(\.identityAddress), [persona1.address])
	}
}

extension ProfileNetwork {
	mutating func hide(account: Account) {
		hideAccount(id: account.id)
	}

	mutating func hide(persona: Persona) {
		hidePersona(id: persona.id)
	}
}
