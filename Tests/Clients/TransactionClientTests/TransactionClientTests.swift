import ClientPrelude
import CryptoKit
import EngineKit
import GatewaysClient
import Profile
import TestingPrelude
import TransactionClient

// MARK: - TransactionClientTests
final class TransactionClientTests: TestCase {
	// MARK: - TransactionFee tests
	func testNormalModeNoLocks() {
		let feeSummary = TransactionFee.FeeSummary(networkFee: 10, royaltyFee: 20)
		let feeLocks = TransactionFee.FeeLocks(nonContingentLock: 0, contingentLock: 0)
		let transaction = TransactionFee(feeSummary: feeSummary, feeLocks: feeLocks, mode: .normal)

		XCTAssertEqual(transaction.networkFee, 11.50)
		XCTAssertEqual(transaction.royaltyFee, 20)
		XCTAssertEqual(transaction.totalFee.lockFee, 31.50)
		XCTAssertEqual(transaction.totalFee.displayedTotalFee, "31.5 XRD")
	}

	func testNormalModeNonContingentLock_1() {
		let feeSummary = TransactionFee.FeeSummary(networkFee: 10, royaltyFee: 20)
		let feeLocks = TransactionFee.FeeLocks(nonContingentLock: 5, contingentLock: 0)
		let transaction = TransactionFee(feeSummary: feeSummary, feeLocks: feeLocks, mode: .normal)

		XCTAssertEqual(transaction.networkFee, 6.50)
		XCTAssertEqual(transaction.royaltyFee, 20)
		XCTAssertEqual(transaction.totalFee.lockFee, 26.50)
		XCTAssertEqual(transaction.totalFee.displayedTotalFee, "26.5 XRD")
	}

	func testNormalModeNonContingentLock_2() {
		let feeSummary = TransactionFee.FeeSummary(networkFee: 10, royaltyFee: 20)
		let feeLocks = TransactionFee.FeeLocks(nonContingentLock: 11.5, contingentLock: 0)
		let transaction = TransactionFee(feeSummary: feeSummary, feeLocks: feeLocks, mode: .normal)

		XCTAssertEqual(transaction.networkFee, 0)
		XCTAssertEqual(transaction.royaltyFee, 20)
		XCTAssertEqual(transaction.totalFee.lockFee, 20)
		XCTAssertEqual(transaction.totalFee.displayedTotalFee, "20 XRD")
	}

	func testNormalModeNonContingentLock_3() {
		let feeSummary = TransactionFee.FeeSummary(networkFee: 10, royaltyFee: 20)
		let feeLocks = TransactionFee.FeeLocks(nonContingentLock: 15, contingentLock: 0)
		let transaction = TransactionFee(feeSummary: feeSummary, feeLocks: feeLocks, mode: .normal)

		XCTAssertEqual(transaction.networkFee, 0)
		XCTAssertEqual(transaction.royaltyFee, 16.5)
		XCTAssertEqual(transaction.totalFee.lockFee, 16.5)
		XCTAssertEqual(transaction.totalFee.displayedTotalFee, "16.5 XRD")
	}

	func testNormalModeNonContingentLock_4() {
		let feeSummary = TransactionFee.FeeSummary(networkFee: 10, royaltyFee: 20)
		let feeLocks = TransactionFee.FeeLocks(nonContingentLock: 31.5, contingentLock: 0)
		let transaction = TransactionFee(feeSummary: feeSummary, feeLocks: feeLocks, mode: .normal)

		XCTAssertEqual(transaction.networkFee, 0)
		XCTAssertEqual(transaction.royaltyFee, 0)
		XCTAssertEqual(transaction.totalFee.lockFee, 0)
		XCTAssertEqual(transaction.totalFee.displayedTotalFee, "0 XRD")
	}

	func testNormalModeNonContingentLock_5() {
		let feeSummary = TransactionFee.FeeSummary(networkFee: 10, royaltyFee: 20)
		let feeLocks = TransactionFee.FeeLocks(nonContingentLock: 100, contingentLock: 0)
		let transaction = TransactionFee(feeSummary: feeSummary, feeLocks: feeLocks, mode: .normal)

		XCTAssertEqual(transaction.networkFee, 0)
		XCTAssertEqual(transaction.royaltyFee, 0)
		XCTAssertEqual(transaction.totalFee.lockFee, 0)
		XCTAssertEqual(transaction.totalFee.displayedTotalFee, "0 XRD")
	}

	func testNormalModeContingentLock_1() {
		let feeSummary = TransactionFee.FeeSummary(networkFee: 10, royaltyFee: 20)
		let feeLocks = TransactionFee.FeeLocks(nonContingentLock: 0, contingentLock: 5)
		let transaction = TransactionFee(feeSummary: feeSummary, feeLocks: feeLocks, mode: .normal)

		XCTAssertEqual(transaction.networkFee, 11.5)
		XCTAssertEqual(transaction.royaltyFee, 20)
		XCTAssertEqual(transaction.totalFee.lockFee, 31.5)
		XCTAssertEqual(transaction.totalFee.displayedTotalFee, "26.5 - 31.5 XRD")
	}

	func testNormalModeContingentLock_2() {
		let feeSummary = TransactionFee.FeeSummary(networkFee: 10, royaltyFee: 20)
		let feeLocks = TransactionFee.FeeLocks(nonContingentLock: 5, contingentLock: 5)
		let transaction = TransactionFee(feeSummary: feeSummary, feeLocks: feeLocks, mode: .normal)

		XCTAssertEqual(transaction.networkFee, 6.5)
		XCTAssertEqual(transaction.royaltyFee, 20)
		XCTAssertEqual(transaction.totalFee.lockFee, 26.5)
		XCTAssertEqual(transaction.totalFee.displayedTotalFee, "21.5 - 26.5 XRD")
	}

	func testAdvancedModeNoLocks() {
		let feeSummary = TransactionFee.FeeSummary(networkFee: 10, royaltyFee: 20)
		let feeLocks = TransactionFee.FeeLocks(nonContingentLock: 0, contingentLock: 0)
		var transaction = TransactionFee(feeSummary: feeSummary, feeLocks: feeLocks, mode: .normal)
		transaction.toggleMode()

		XCTAssertEqual(transaction.totalFee.lockFee, 31.5)
		XCTAssertEqual(transaction.totalFee.displayedTotalFee, "31.5 XRD")
	}

	func testAdvancedModeLocks() {
		let feeSummary = TransactionFee.FeeSummary(networkFee: 10, royaltyFee: 20)
		let feeLocks = TransactionFee.FeeLocks(nonContingentLock: 5, contingentLock: 5)
		var transaction = TransactionFee(feeSummary: feeSummary, feeLocks: feeLocks, mode: .normal)
		transaction.toggleMode()

		XCTAssertEqual(transaction.totalFee.lockFee, 26.5)
		XCTAssertEqual(transaction.totalFee.displayedTotalFee, "26.5 XRD")
	}

	func testAdvancedModeEdited_1() {
		let feeSummary = TransactionFee.FeeSummary(networkFee: 10, royaltyFee: 20)
		let feeLocks = TransactionFee.FeeLocks(nonContingentLock: 5, contingentLock: 5)
		var transaction = TransactionFee(feeSummary: feeSummary, feeLocks: feeLocks, mode: .normal)
		transaction.mode = .advanced(.init(networkAndRoyaltyFee: 20, tipPercentage: .zero))

		XCTAssertEqual(transaction.totalFee.lockFee, 20)
		XCTAssertEqual(transaction.totalFee.displayedTotalFee, "20 XRD")
	}

	func testAdvancedModeEdited_2() {
		let feeSummary = TransactionFee.FeeSummary(networkFee: 10, royaltyFee: 20)
		let feeLocks = TransactionFee.FeeLocks(nonContingentLock: 0, contingentLock: 0)
		var transaction = TransactionFee(feeSummary: feeSummary, feeLocks: feeLocks, mode: .normal)
		transaction.mode = .advanced(.init(networkAndRoyaltyFee: 50, tipPercentage: 50))

		// 50 - royaltyFee(20) = 30
		// 30 * 0.5 = 15
		// 50 + 15 = 65
		XCTAssertEqual(transaction.totalFee.lockFee, 65.0)
		XCTAssertEqual(transaction.totalFee.displayedTotalFee, "65 XRD")
	}

	func testAdvancedModeEdited_3() {
		let feeSummary = TransactionFee.FeeSummary(networkFee: 10, royaltyFee: 20)
		let feeLocks = TransactionFee.FeeLocks(nonContingentLock: 0, contingentLock: 0)
		var transaction = TransactionFee(feeSummary: feeSummary, feeLocks: feeLocks, mode: .normal)
		transaction.mode = .advanced(.init(networkAndRoyaltyFee: 25, tipPercentage: 50))

		// 25 - royaltyFee(20) = 5
		// 5 * 0.5 = 2.5
		// 25 + 2.5 = 27.5
		XCTAssertEqual(transaction.totalFee.lockFee, 27.5)
		XCTAssertEqual(transaction.totalFee.displayedTotalFee, "27.5 XRD")
	}

	func testAdvancedModeEdited_4() {
		let feeSummary = TransactionFee.FeeSummary(networkFee: 10, royaltyFee: 20)
		let feeLocks = TransactionFee.FeeLocks(nonContingentLock: 0, contingentLock: 0)
		var transaction = TransactionFee(feeSummary: feeSummary, feeLocks: feeLocks, mode: .normal)
		transaction.mode = .advanced(.init(networkAndRoyaltyFee: 15, tipPercentage: 50))

		// 15 - royaltyFee(20) = 0 ?? Ignore royalty fee and use the whole amount as network fee
		// 0 * 0.5 = 0.0
		// 15 + 0.0= 22.5
		XCTAssertEqual(transaction.totalFee.lockFee, 15)
		XCTAssertEqual(transaction.totalFee.displayedTotalFee, "15 XRD")
	}

	func testAdvancedModeEdited_5() {
		let feeSummary = TransactionFee.FeeSummary(networkFee: 10, royaltyFee: 20)
		let feeLocks = TransactionFee.FeeLocks(nonContingentLock: 26.5, contingentLock: 10)
		var transaction = TransactionFee(feeSummary: feeSummary, feeLocks: feeLocks, mode: .normal)
		transaction.mode = .advanced(.init(networkAndRoyaltyFee: 25, tipPercentage: 50))

		// 25 - royaltyFee(5) = 20
		// 20 * 0.5 = 10
		// 25 + 10 = 30
		XCTAssertEqual(transaction.totalFee.lockFee, 35)
		XCTAssertEqual(transaction.totalFee.displayedTotalFee, "35 XRD")
	}
}

extension Profile.Network.Account {
	static func new(address: String) -> Self {
		try! .init(
			networkID: .simulator,
			address: AccountAddress(validatingAddress: address),
			factorInstance: .init(
				factorSourceID: .previewValue,
				publicKey: .eddsaEd25519(Curve25519.Signing.PrivateKey().publicKey),
				derivationPath: AccountDerivationPath.babylon(.init(
					networkID: .simulator,
					index: 0,
					keyKind: .transactionSigning
				)).wrapAsDerivationPath()
			),
			displayName: "acc",
			extraProperties: .init(
				appearanceID: ._0
			)
		)
	}
}
