import Asset
import FungibleTokenListFeature
import Profile
import TestUtils

final class FungibleTokenListSortingTests: TestCase {
	let account = try! OnNetwork.Account(
		address: OnNetwork.Account.EntityAddress(
			address: "account_tdx_a_1qwv0unmwmxschqj8sntg6n9eejkrr6yr6fa4ekxazdzqhm6wy5"
		),
		securityState: .unsecured(.init(
			genesisFactorInstance: .curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorInstance(.init(
				factorSourceReference: .init(
					factorSourceKind: .curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorSourceKind,
					factorSourceID: "09bfa80bcc9b75d6ad82d59730f7b179cbc668ba6ad4008721d5e6a179ff55f1"
				),
				publicKey: .eddsaEd25519(.init(
					compressedRepresentation: Data(
						hex: "7bf9f97c0cac8c6c112d716069ccc169283b9838fa2f951c625b3d4ca0a8f05b")
				)),
				derivationPath: .accountPath(.init(derivationPath: "m/44H/1022H/10H/525H/0H/1238H"))
			)
			)
		)),
		index: 0,
		derivationPath: .init(derivationPath: "m/44H/1022H/10H/525H/0H/1238H"),
		displayName: "Main"
	)
	var address: AccountAddress { account.address }

	func test_sortTokensWithValues() {
		// given
		let btc = FungibleToken.btc
		let eth = FungibleToken.eth
		let ltc = FungibleToken.ltc
		let xrd = FungibleToken.xrd
		let dot = FungibleToken.dot

		let btcContainer = FungibleTokenContainer(owner: address, asset: btc, amount: nil, worth: 1)
		let ethContainer = FungibleTokenContainer(owner: address, asset: eth, amount: nil, worth: 2)
		let ltcContainer = FungibleTokenContainer(owner: address, asset: ltc, amount: nil, worth: 3)
		let xrdContainer = FungibleTokenContainer(owner: address, asset: xrd, amount: nil, worth: 4)
		let dotContainer = FungibleTokenContainer(owner: address, asset: dot, amount: nil, worth: 5)

		// when
		let result = [btcContainer, ethContainer, ltcContainer, xrdContainer, dotContainer].sortedIntoCategories()

		// then
		let expectedResult = [
			FungibleTokenCategory(type: .xrd, tokenContainers: [xrdContainer]),
			FungibleTokenCategory(type: .nonXrd, tokenContainers: [dotContainer, ltcContainer, ethContainer, btcContainer]),
		]
		XCTAssertEqual(result, expectedResult)
	}

	func test_sortTokensWithNoValues() {
		// given
		let btc = FungibleToken.btc
		let eth = FungibleToken.eth
		let ltc = FungibleToken.ltc
		let xrd = FungibleToken.xrd
		let dot = FungibleToken.dot

		let btcContainer = FungibleTokenContainer(owner: address, asset: btc, amount: nil, worth: nil)
		let ethContainer = FungibleTokenContainer(owner: address, asset: eth, amount: nil, worth: nil)
		let ltcContainer = FungibleTokenContainer(owner: address, asset: ltc, amount: nil, worth: nil)
		let xrdContainer = FungibleTokenContainer(owner: address, asset: xrd, amount: nil, worth: nil)
		let dotContainer = FungibleTokenContainer(owner: address, asset: dot, amount: nil, worth: nil)

		// when
		let result = [btcContainer, ethContainer, ltcContainer, xrdContainer, dotContainer].sortedIntoCategories()

		// then
		let expectedResult = [
			FungibleTokenCategory(type: .xrd, tokenContainers: [xrdContainer]),
			FungibleTokenCategory(type: .nonXrd, tokenContainers: [btcContainer, dotContainer, ethContainer, ltcContainer]),
		]
		XCTAssertEqual(result, expectedResult)
	}

	func test_sortTokensWithAndWithNoValues() {
		// given
		let btc = FungibleToken.btc
		let eth = FungibleToken.eth
		let ltc = FungibleToken.ltc
		let xrd = FungibleToken.xrd
		let dot = FungibleToken.dot

		let btcContainer = FungibleTokenContainer(owner: address, asset: btc, amount: nil, worth: nil)
		let ethContainer = FungibleTokenContainer(owner: address, asset: eth, amount: nil, worth: 2)
		let ltcContainer = FungibleTokenContainer(owner: address, asset: ltc, amount: nil, worth: 3)
		let xrdContainer = FungibleTokenContainer(owner: address, asset: xrd, amount: nil, worth: nil)
		let dotContainer = FungibleTokenContainer(owner: address, asset: dot, amount: nil, worth: nil)

		// when
		let result = [btcContainer, ethContainer, ltcContainer, xrdContainer, dotContainer].sortedIntoCategories()

		// then
		let expectedResult = [
			FungibleTokenCategory(type: .xrd, tokenContainers: [xrdContainer]),
			FungibleTokenCategory(type: .nonXrd, tokenContainers: [ltcContainer, ethContainer, btcContainer, dotContainer]),
		]
		XCTAssertEqual(result, expectedResult)
	}
}
