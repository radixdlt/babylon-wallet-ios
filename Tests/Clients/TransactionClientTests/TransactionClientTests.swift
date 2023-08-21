import ClientPrelude
import CryptoKit
import EngineKit
import GatewaysClient
import Profile
import TestingPrelude
import TransactionClient

// MARK: - TransactionClientTests
final class TransactionClientTests: TestCase {
	let feeSummary = TransactionFee.FeeSummary(
		executionCost: 5,
		finalizationCost: 5,
		storageExpansionCost: 5,
		royaltyCost: 10
	)

	// MARK: - TransactionFee tests
	func testNormalModeNoLocks() throws {
		let noLocks = TransactionFee.FeeLocks(nonContingentLock: 0, contingentLock: 0)
		let transaction = TransactionFee(feeSummary: feeSummary, feeLocks: noLocks)

		try assertNormalModeFees(for: transaction)
	}

	func testNormalModeNonContingentLock_1() throws {
		let feeLocks = TransactionFee.FeeLocks(nonContingentLock: 5, contingentLock: 0)
		let transaction = TransactionFee(feeSummary: feeSummary, feeLocks: feeLocks)

		try assertNormalModeFees(for: transaction)
	}

	func testNormalModeNonContingentLock_2() throws {
		let feeLocks = TransactionFee.FeeLocks(nonContingentLock: 17.25, contingentLock: 0)
		let transaction = TransactionFee(feeSummary: feeSummary, feeLocks: feeLocks)
		try assertNormalModeFees(for: transaction)
	}

	func testNormalModeNonContingentLock_3() throws {
		let feeLocks = TransactionFee.FeeLocks(nonContingentLock: 27.25, contingentLock: 0)
		let transaction = TransactionFee(feeSummary: feeSummary, feeLocks: feeLocks)

		try assertNormalModeFees(for: transaction)
	}

	func testNormalModeNonContingentLock_5() throws {
		let feeLocks = TransactionFee.FeeLocks(nonContingentLock: 100, contingentLock: 0)
		let transaction = TransactionFee(feeSummary: feeSummary, feeLocks: feeLocks)

		try assertNormalModeFees(for: transaction)
	}

	func testNormalMode_contingentLock() throws {
		let feeLocks = TransactionFee.FeeLocks(nonContingentLock: 0, contingentLock: 5)
		let transaction = TransactionFee(feeSummary: feeSummary, feeLocks: feeLocks)

		try assertNormalModeFees(for: transaction)
	}

	func testNormalMode_contingentLock_with_nonContingentLock() throws {
		let feeLocks = TransactionFee.FeeLocks(nonContingentLock: 5, contingentLock: 5)
		let transaction = TransactionFee(feeSummary: feeSummary, feeLocks: feeLocks)

		try assertNormalModeFees(for: transaction)
	}

	func testNormalMode_contingentLock_bigValue() throws {
		let feeLocks = TransactionFee.FeeLocks(nonContingentLock: 5, contingentLock: 100)
		let transaction = TransactionFee(feeSummary: feeSummary, feeLocks: feeLocks)

		try assertNormalModeFees(for: transaction)
	}

	func testNormalMode_contingentLock_with_nonContingentLock_bigValue() throws {
		let feeLocks = TransactionFee.FeeLocks(nonContingentLock: 100, contingentLock: 100)
		let transaction = TransactionFee(feeSummary: feeSummary, feeLocks: feeLocks)

		try assertNormalModeFees(for: transaction)
	}

	func testAdvancedMode() throws {
		let feeLocks = TransactionFee.FeeLocks(nonContingentLock: 100, contingentLock: 100)
		var advancedMode = TransactionFee.AdvancedFeeCustomization(feeSummary: feeSummary)
		advancedMode.tipPercentage = 10

		var transaction = TransactionFee(feeSummary: feeSummary, feeLocks: feeLocks, mode: .advanced(advancedMode))

		let networkFee = feeSummary.executionCost + feeSummary.finalizationCost
		let feesTotal = feeSummary.executionCost + feeSummary.finalizationCost + feeSummary.storageExpansionCost + feeSummary.royaltyCost
		let defaultPaddingFee = networkFee * TransactionFee.PredefinedFeeConstants.networkFeeMultiplier

		XCTAssertNotNil(transaction.advanced, "Expected to switch to advanced mode")
		XCTAssertEqual(advancedMode.paddingFee, defaultPaddingFee)
		XCTAssertEqual(advancedMode.tipPercentage, 10)
		XCTAssertEqual(advancedMode.tipAmount, networkFee * 0.1)

		let totalFee = feesTotal + advancedMode.paddingFee + advancedMode.tipAmount
		XCTAssertEqual(transaction.totalFee, .init(min: totalFee, max: totalFee))
	}

	func assertNormalModeFees(for transaction: TransactionFee) throws {
		let normalMode = try XCTUnwrap(transaction.normal, "Expected default mode to be normal")
		XCTAssertEqual(normalMode.networkFee, transaction.expectedNormalModeNetworkFee)
		XCTAssertEqual(normalMode.royaltyFee, transaction.expectedNormalModeRoyaltyFee)
		XCTAssertEqual(transaction.totalFee.lockFee, transaction.expectedNormalModeLockFee)
		XCTAssertEqual(transaction.totalFee, transaction.expectedNormalModeTotalFee)
	}
}

extension TransactionFee {
	var normalModeNetworkFee: BigDecimal {
		var networkFee = feeSummary.executionCost + feeSummary.finalizationCost + feeSummary.storageExpansionCost
		networkFee += networkFee * PredefinedFeeConstants.networkFeeMultiplier
		return networkFee
	}

	var expectedNormalModeNetworkFee: BigDecimal {
		var networkFee = feeSummary.executionCost + feeSummary.finalizationCost + feeSummary.storageExpansionCost
		networkFee += networkFee * PredefinedFeeConstants.networkFeeMultiplier

		return networkFee.clampedDiff(feeLocks.nonContingentLock)
	}

	var expectedNormalModeRoyaltyFee: BigDecimal {
		let remainingNonContingentLock = feeLocks.nonContingentLock.clampedDiff(normalModeNetworkFee)
		return feeSummary.royaltyCost.clampedDiff(remainingNonContingentLock)
	}

	var expectedNormalModeLockFee: BigDecimal {
		expectedNormalModeNetworkFee + expectedNormalModeRoyaltyFee
	}

	var expectedNormalModeTotalFee: TotalFee {
		let maxFee = expectedNormalModeLockFee
		let minFee = maxFee.clampedDiff(feeLocks.contingentLock)
		return .init(min: minFee, max: maxFee)
	}

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
