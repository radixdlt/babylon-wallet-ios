import EngineToolkit
@testable import Radix_Wallet_Dev
import XCTest

// MARK: - EntitiesHidingTests
final class EntitiesHidingTests: TestCase {
	let account0 = Profile.Network.Account.testValueIdx0
	let account1 = Profile.Network.Account.testValueIdx1

	let persona0 = Profile.Network.Persona.testValueIdx0
	let persona1 = Profile.Network.Persona.testValueIdx1

	lazy var sharedPersona0 = try! Profile.Network.AuthorizedDapp.AuthorizedPersonaSimple(
		identityAddress: persona0.address,
		lastLogin: .now,
		sharedAccounts: .init(ids: [account0.address, account1.address], forRequest: .atLeast(1)),
		sharedPersonaData: .init()
	)

	lazy var sharedPersona1 = try! Profile.Network.AuthorizedDapp.AuthorizedPersonaSimple(
		identityAddress: persona1.address,
		lastLogin: .now,
		sharedAccounts: .init(ids: [account0.address, account1.address], forRequest: .atLeast(1)),
		sharedPersonaData: .init()
	)

	lazy var dApp0 = try! Profile.Network.AuthorizedDapp(
		networkID: .mainnet,
		dAppDefinitionAddress: try! .init(validatingAddress: "account_rdx12xsvygvltz4uhsht6tdrfxktzpmnl77r0d40j8agmujgdj022sudkk"),
		displayName: "name 0",
		referencesToAuthorizedPersonas: [sharedPersona0]
	)

	lazy var dApp1 = try! Profile.Network.AuthorizedDapp(
		networkID: .mainnet,
		dAppDefinitionAddress: try! .init(validatingAddress: "account_rdx1283u6e8r2jnz4a3jwv0hnrqfr5aq50yc9ts523sd96hzfjxqqcs89q"),
		displayName: "name 1",
		referencesToAuthorizedPersonas: [sharedPersona0, sharedPersona1]
	)

	lazy var network = try! Profile.Network(
		networkID: .mainnet,
		accounts: .init(rawValue: [account0, account1])!,
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

	func test_GIVEN_hasHiddenAccounts_WHEN_askingForNextAccountIndex_THEN_returnsProperValue() {
		var sut = network
		sut.hide(account: account0)
		sut.hide(account: account1)
		XCTAssertEqual(sut.nextAccountIndex(), 2)
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

	func test_GIVEN_hasHiddenPersonas_WHEN_askingForNextPersonaIndex_THEN_returnsProperValue() {
		var sut = network
		sut.hide(persona: persona0)
		sut.hide(persona: persona1)
		XCTAssertEqual(sut.nextPersonaIndex(), 2)
	}

	func test_GIVEN_hasSharedAccountsWithDapps_WHEN_accountIsHidden_THEN_accountIsRemovedFromSharedAccounts() {
		var sut = network
		sut.hide(account: account0)

		let authorizedDapp0 = sut.authorizedDapps[id: dApp0.id]!
		let authorizedDapp1 = sut.authorizedDapps[id: dApp1.id]!

		/// Assert that account0 is not present anymore, but account1 is still kept.
		XCTAssertEqual(authorizedDapp0.referencesToAuthorizedPersonas[id: sharedPersona0.id]?.sharedAccounts?.ids, [account1.address])
		XCTAssertEqual(authorizedDapp1.referencesToAuthorizedPersonas[id: sharedPersona0.id]?.sharedAccounts?.ids, [account1.address])
		XCTAssertEqual(authorizedDapp1.referencesToAuthorizedPersonas[id: sharedPersona1.id]?.sharedAccounts?.ids, [account1.address])
	}

	func test_GIVEN_hasAuthorizedDappsWithOnePersona_WHEN_personaIsHidden_THEN_dappIsRemoved() {
		var sut = network
		sut.hide(persona: persona0)

		/// dApp0 references only persona0
		XCTAssertNil(sut.authorizedDapps[id: dApp0.id])
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

extension Profile.Network {
	mutating func hide(account: Profile.Network.Account) {
		hideAccounts(ids: [account.id])
	}

	mutating func hide(persona: Profile.Network.Persona) {
		hidePersonas(ids: [persona.id])
	}
}
