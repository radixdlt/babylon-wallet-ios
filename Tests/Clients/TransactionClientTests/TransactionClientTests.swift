import ClientPrelude
import CryptoKit
import EngineKit
import GatewaysClient
import Profile
import TestingPrelude
import TransactionClient

// MARK: - TransactionClientTests
final class TransactionClientTests: TestCase {
	let feeSummary = try! FeeSummary(
		executionCost: .init(value: "5"),
		finalizationCost: .init(value: "5"),
		storageExpansionCost: .init(value: "5"),
		royaltyCost: .init(value: "10")
	)

	// MARK: - TransactionFee tests
	func testNormalModeNoLocks() throws {
		let noLocks = FeeLocks(lock: .zero(), contingentLock: .zero())
		let analysis = ExecutionAnalysis(
			feeLocks: noLocks,
			feeSummary: feeSummary,
			transactionTypes: [],
			reservedInstructions: []
		)
		let transaction = try TransactionFee(executionAnalysis: analysis)
		XCTAssertNotNil(transaction.normal, "Expected default mode to be normal")
		XCTAssertEqual(transaction.normal?.networkFee, 17.25)
		XCTAssertEqual(transaction.normal?.royaltyFee, 10)
		XCTAssertEqual(transaction.totalFee.lockFee, 27.25)
		XCTAssertEqual(transaction.totalFee.displayedTotalFee, "27.25 XRD")
	}

	func testNormalModeNonContingentLock_1() throws {
		let feeLocks = try! FeeLocks(lock: .init(value: "5"), contingentLock: .zero())
		let analysis = ExecutionAnalysis(
			feeLocks: feeLocks,
			feeSummary: feeSummary,
			transactionTypes: [],
			reservedInstructions: []
		)
		let transaction = try TransactionFee(executionAnalysis: analysis)
		XCTAssertNotNil(transaction.normal, "Expected default mode to be normal")
		XCTAssertEqual(transaction.normal?.networkFee, 12.25)
		XCTAssertEqual(transaction.normal?.royaltyFee, 10)
		XCTAssertEqual(transaction.totalFee.lockFee, 22.25)
		XCTAssertEqual(transaction.totalFee.displayedTotalFee, "22.25 XRD")
	}

	func testNormalModeNonContingentLock_2() throws {
		let feeLocks = try! FeeLocks(lock: .init(value: "17.25"), contingentLock: .zero())
		let analysis = ExecutionAnalysis(
			feeLocks: feeLocks,
			feeSummary: feeSummary,
			transactionTypes: [],
			reservedInstructions: []
		)
		let transaction = try TransactionFee(executionAnalysis: analysis)
		XCTAssertNotNil(transaction.normal, "Expected default mode to be normal")
		XCTAssertEqual(transaction.normal?.networkFee, 0)
		XCTAssertEqual(transaction.normal?.royaltyFee, 10)
		XCTAssertEqual(transaction.totalFee.lockFee, 10)
		XCTAssertEqual(transaction.totalFee.displayedTotalFee, "10 XRD")
	}

	func testNormalModeNonContingentLock_4() throws {
		let feeLocks = try! FeeLocks(lock: .init(value: "27.25"), contingentLock: .zero())
		let analysis = ExecutionAnalysis(
			feeLocks: feeLocks,
			feeSummary: feeSummary,
			transactionTypes: [],
			reservedInstructions: []
		)
		let transaction = try TransactionFee(executionAnalysis: analysis)
		XCTAssertNotNil(transaction.normal, "Expected default mode to be normal")
		XCTAssertEqual(transaction.normal?.networkFee, 0)
		XCTAssertEqual(transaction.normal?.royaltyFee, 0)
		XCTAssertEqual(transaction.totalFee.lockFee, 0)
		XCTAssertEqual(transaction.totalFee.displayedTotalFee, "0 XRD")
	}

	func testNormalModeNonContingentLock_5() throws {
		let feeLocks = try! FeeLocks(lock: .init(value: "100"), contingentLock: .zero())
		let analysis = ExecutionAnalysis(
			feeLocks: feeLocks,
			feeSummary: feeSummary,
			transactionTypes: [],
			reservedInstructions: []
		)
		let transaction = try TransactionFee(executionAnalysis: analysis)
		XCTAssertNotNil(transaction.normal, "Expected default mode to be normal")
		XCTAssertEqual(transaction.normal?.networkFee, 0)
		XCTAssertEqual(transaction.normal?.royaltyFee, 0)
		XCTAssertEqual(transaction.totalFee.lockFee, 0)
		XCTAssertEqual(transaction.totalFee.displayedTotalFee, "0 XRD")
	}

	func testNormalMode_contingentLock() throws {
		let feeLocks = try! FeeLocks(lock: .zero(), contingentLock: .init(value: "5"))
		let analysis = ExecutionAnalysis(
			feeLocks: feeLocks,
			feeSummary: feeSummary,
			transactionTypes: [],
			reservedInstructions: []
		)
		let transaction = try TransactionFee(executionAnalysis: analysis)
		XCTAssertNotNil(transaction.normal, "Expected default mode to be normal")
		XCTAssertEqual(transaction.normal?.networkFee, 17.25)
		XCTAssertEqual(transaction.normal?.royaltyFee, 10)
		XCTAssertEqual(transaction.totalFee.lockFee, 27.25)
		XCTAssertEqual(transaction.totalFee.displayedTotalFee, "22.25 - 27.25 XRD")
	}

	func testNormalMode_contingentLock_with_nonContingentLock() throws {
		let feeLocks = try! FeeLocks(lock: .init(value: "5"), contingentLock: .init(value: "5"))
		let analysis = ExecutionAnalysis(
			feeLocks: feeLocks,
			feeSummary: feeSummary,
			transactionTypes: [],
			reservedInstructions: []
		)
		let transaction = try TransactionFee(executionAnalysis: analysis)
		XCTAssertNotNil(transaction.normal, "Expected default mode to be normal")
		XCTAssertEqual(transaction.normal?.networkFee, 12.25)
		XCTAssertEqual(transaction.normal?.royaltyFee, 10)
		XCTAssertEqual(transaction.totalFee.lockFee, 22.25)
		XCTAssertEqual(transaction.totalFee.displayedTotalFee, "17.25 - 22.25 XRD")
	}

	func testNormalMode_contingentLock_maxValue() throws {
		let feeLocks = try! FeeLocks(lock: .init(value: "5"), contingentLock: .max())
		let analysis = ExecutionAnalysis(
			feeLocks: feeLocks,
			feeSummary: feeSummary,
			transactionTypes: [],
			reservedInstructions: []
		)
		let transaction = try TransactionFee(executionAnalysis: analysis)
		XCTAssertNotNil(transaction.normal, "Expected default mode to be normal")
		XCTAssertEqual(transaction.normal?.networkFee, 12.25)
		XCTAssertEqual(transaction.normal?.royaltyFee, 10)
		XCTAssertEqual(transaction.totalFee.lockFee, 22.25)
		XCTAssertEqual(transaction.totalFee.displayedTotalFee, "0 - 22.25 XRD")
	}

	func testNormalMode_contingentLock_with_nonContingentLock_max() throws {
		let feeLocks = FeeLocks(lock: .max(), contingentLock: .max())
		let analysis = ExecutionAnalysis(
			feeLocks: feeLocks,
			feeSummary: feeSummary,
			transactionTypes: [],
			reservedInstructions: []
		)
		let transaction = try TransactionFee(executionAnalysis: analysis)
		XCTAssertNotNil(transaction.normal, "Expected default mode to be normal")
		XCTAssertEqual(transaction.normal?.networkFee, 0)
		XCTAssertEqual(transaction.normal?.royaltyFee, 0)
		XCTAssertEqual(transaction.totalFee.lockFee, 0)
		XCTAssertEqual(transaction.totalFee.displayedTotalFee, "0 XRD")
	}

	func testAdvancedMode() throws {
		let locks = FeeLocks(lock: .max(), contingentLock: .max())
		let analysis = ExecutionAnalysis(
			feeLocks: locks,
			feeSummary: feeSummary,
			transactionTypes: [],
			reservedInstructions: []
		)
		var transaction = try TransactionFee(executionAnalysis: analysis)
		transaction.toggleMode()

		XCTAssertNotNil(transaction.advanced, "Expected default mode to be advanced")
		XCTAssertEqual(transaction.advanced?.paddingFee, 1.5)
		XCTAssertEqual(transaction.advanced?.tipPercentage, 0)
		XCTAssertEqual(transaction.advanced?.total, 26.50)
		XCTAssertEqual(transaction.totalFee.displayedTotalFee, "26.5 XRD")
	}

	func testAdvancedMode_edit() throws {
		let locks = FeeLocks(lock: .max(), contingentLock: .max())
		let analysis = ExecutionAnalysis(
			feeLocks: locks,
			feeSummary: feeSummary,
			transactionTypes: [],
			reservedInstructions: []
		)
		var transaction = try TransactionFee(executionAnalysis: analysis)
		transaction.toggleMode()

		XCTAssertNotNil(transaction.advanced, "Expected default mode to be advanced")
		var advanced = transaction.advanced!
		advanced.paddingFee = 5
		advanced.tipPercentage = 20
		transaction.mode = .advanced(advanced)

		XCTAssertEqual(transaction.advanced?.paddingFee, 5.0)
		XCTAssertEqual(transaction.advanced?.tipPercentage, 20.0)
		XCTAssertEqual(transaction.advanced?.tipAmount, 2.0)
		XCTAssertEqual(transaction.advanced?.total, 32.0)
		XCTAssertEqual(transaction.totalFee.displayedTotalFee, "32 XRD")
	}
}

extension TransactionFee {
	var normal: TransactionFee.NormalFeeCustomization? {
		guard case let .normal(normal) = self.mode else {
			return nil
		}
		return normal
	}

	var advanced: TransactionFee.AdvancedFeeCustomization? {
		guard case let .advanced(advanced) = self.mode else {
			return nil
		}
		return advanced
	}
}

extension Profile.Network.Account {
	static func new(address: String) -> Self {
		try! .init(
			networkID: .simulator,
			index: 0,
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
