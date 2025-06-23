@testable import Radix_Wallet_Dev
import Sargon
import XCTest

// MARK: - Decimal192 + ExpressibleByFloatLiteral
extension Decimal192: ExpressibleByFloatLiteral {
	public init(floatLiteral value: Double) {
		try! self.init(value)
	}
}

// MARK: - TransactionClientTests
final class TransactionClientTests: TestCase {
	let feeSummary = TransactionFee.FeeSummary(
		executionCost: 5,
		finalizationCost: 5,
		storageExpansionCost: 5,
		royaltyCost: 10,
		guaranteesCost: 5,
		signaturesCost: 5,
		lockFeeCost: 5,
		notarizingCost: 5
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
		// A non contingent lock that can pay for the whole lock fee
		let feeLocks = TransactionFee.FeeLocks(nonContingentLock: 40.25, contingentLock: 0)
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
		let feeLocks = TransactionFee.FeeLocks(nonContingentLock: 10, contingentLock: 0)
		var advancedMode = TransactionFee.AdvancedFeeCustomization(feeSummary: feeSummary, feeLocks: feeLocks)
		advancedMode.tipPercentage = 10

		let transaction = TransactionFee(feeSummary: feeSummary, feeLocks: feeLocks, mode: .advanced(advancedMode))

		let networkFee = feeSummary.totalExecutionCost + feeSummary.finalizationCost + feeSummary.storageExpansionCost
		let feesTotal = feeSummary.totalExecutionCost + feeSummary.finalizationCost + feeSummary.storageExpansionCost + feeSummary.royaltyCost
		let defaultPaddingFee = networkFee * TransactionFee.PredefinedFeeConstants.networkFeeMultiplier

		XCTAssertNotNil(transaction.advanced, "Expected to switch to advanced mode")
		XCTAssertEqual(advancedMode.paddingFee, defaultPaddingFee)
		XCTAssertEqual(advancedMode.tipPercentage, 10)
		XCTAssertEqual(advancedMode.tipAmount, (feeSummary.totalExecutionCost + feeSummary.finalizationCost) * 0.1)

		let totalFee = feesTotal + advancedMode.paddingFee + advancedMode.tipAmount - feeLocks.nonContingentLock
		XCTAssertEqual(transaction.totalFee, .init(min: totalFee, max: totalFee))
	}

	func assertNormalModeFees(for transaction: TransactionFee) throws {
		let normalMode = try XCTUnwrap(transaction.normal, "Expected default mode to be normal")
		XCTAssertEqual(normalMode.networkFee, transaction.expectedNormalModeNetworkFee)
		XCTAssertEqual(normalMode.royaltyFee, transaction.expectedNormalModeRoyaltyFee)
		XCTAssertEqual(transaction.totalFee.lockFee, transaction.expectedNormalModeLockFee)
		XCTAssertEqual(transaction.totalFee, transaction.expectedNormalModeTotalFee)
	}

	func testSelectFeePayerTests() async throws {
		var txFee = testTransactionFee()
		let sut = TransactionClient.testValue

		let accounts: [Account] = [
			.new(factorSource: .deviceOne, index: 0), // 0
			.new(factorSource: .deviceOne, index: 1), // 1
			.new(factorSource: .deviceTwo, index: 0), // 2
			.new(factorSource: .ledgerTwo, index: 0), // 3
			.new(factorSource: .ledgerTwo, index: 1), // 4
			.new(factorSource: .ledgerTwo, index: 2), // 5
		]

		let signersAfterAnalysis = Array(accounts.prefix(2))
		txFee.updateSignaturesCost(signersAfterAnalysis.count)
		let defaultCandidates = signersAfterAnalysis.map { FeePayerCandidate(account: $0, xrdBalance: txFee.totalFee.lockFee / 2) }

		let potentialCandidate1 = FeePayerCandidate(account: accounts[4], xrdBalance: txFee.totalFee.lockFee - TransactionFee.PredefinedFeeConstants.signatureCost)
		let potentialCandidate2 = FeePayerCandidate(account: accounts[5], xrdBalance: txFee.totalFee.lockFee + 10)

		let allFeePayerCandidates = defaultCandidates + [potentialCandidate1, potentialCandidate2]

		let notary = Curve25519.Signing.PrivateKey()

		let defaultSigners = TransactionSigners(
			notaryPublicKey: notary.publicKey,
			intentSigning: .intentSigners(
				.init(rawValue: OrderedSet(signersAfterAnalysis.map { .account($0) }))!
			)
		)

		let defaultFactors = signersAfterAnalysis.map(\.signingFactor)

		let result = try await withDependencies {
			$0.factorSourcesClient.getSigningFactors = { request in
				try [.device: .init(rawValue: Set(request.signers.rawValue.map {
					try SigningFactor(
						factorSource: .deviceOne,
						signer: .init(factorInstancesRequiredToSign: $0.virtualHierarchicalDeterministicFactorInstances, of: $0)
					)
				}))!]
			}
			$0.secureStorageClient.saveDeviceInfo = { _ in }
			$0.secureStorageClient.loadDeviceInfo = { nil }
		} operation: {
			try await TransactionClient.feePayerSelectionAmongstCandidates(
				request: .init(
					networkId: .mainnet,
					transactionFee: txFee,
					transactionSigners: defaultSigners,
					signingFactors: [.device: .init(rawValue: Set(defaultFactors))!],
					signingPurpose: .signTransaction(.manifestFromDapp),
					manifest: TransactionManifest.sample,
					accountWithdraws: [:]
				),
				feePayerCandidates: allFeePayerCandidates.asIdentified(),
				involvedEntities: .init(
					identitiesRequiringAuth: [],
					accountsRequiringAuth: OrderedSet(signersAfterAnalysis),
					accountsWithdrawnFrom: OrderedSet(signersAfterAnalysis),
					accountsDepositedInto: OrderedSet(accounts.suffix(2))
				),
				accountWithdraws: [:]
			)
		}

		let unwrapedResult = try XCTUnwrap(result)

		/// Proper fee payer was determined
		XCTAssertEqual(unwrapedResult.payer, potentialCandidate2)

		let expectedSigners = defaultSigners.intentSignerEntitiesOrEmpty().union([.account(potentialCandidate2.account)])
		/// The FeePayer signature was added to transactionSigners
		XCTAssertEqual(
			unwrapedResult.transactionSigners.intentSignerEntitiesOrEmpty(),
			expectedSigners
		)

		let expectedfactorsForDevice = defaultFactors + [potentialCandidate2.account.signingFactor]
		let expectedFactors: SigningFactors = [.device: .init(rawValue: Set(expectedfactorsForDevice))!]

		/// The FeePayer signing factor was added
		XCTAssertEqual(unwrapedResult.signingFactors, expectedFactors)

		txFee.updateSignaturesCost(expectedFactors.expectedSignatureCount)
		/// The lockFee was increased with the additional signature cost.
		XCTAssertEqual(unwrapedResult.updatedFee.totalFee.lockFee, txFee.totalFee.lockFee)
	}

	private func testTransactionFee() -> TransactionFee {
		.init(feeSummary: feeSummary, feeLocks: .init(nonContingentLock: .zero, contingentLock: .zero))
	}
}

extension Account {
	var signingFactor: SigningFactor {
		try! .init(
			factorSource: .deviceOne,
			signer: .init(factorInstancesRequiredToSign: virtualHierarchicalDeterministicFactorInstances, of: .account(self))
		)
	}
}

extension TransactionFee {
	var normalModeNetworkFee: Decimal192 {
		let networkFee = feeSummary.executionCost
			+ feeSummary.finalizationCost
			+ feeSummary.storageExpansionCost
			+ feeSummary.guaranteesCost
			+ feeSummary.lockFeeCost
			+ feeSummary.signaturesCost
			+ feeSummary.notarizingCost

		return networkFee * (1 + PredefinedFeeConstants.networkFeeMultiplier)
	}

	var expectedNormalModeNetworkFee: Decimal192 {
		(normalModeNetworkFee - feeLocks.nonContingentLock).clamped
	}

	var expectedNormalModeRoyaltyFee: Decimal192 {
		let remainingNonContingentLock = (feeLocks.nonContingentLock - normalModeNetworkFee).clamped
		return (feeSummary.royaltyCost - remainingNonContingentLock).clamped
	}

	var expectedNormalModeLockFee: Decimal192 {
		expectedNormalModeNetworkFee + expectedNormalModeRoyaltyFee
	}

	var expectedNormalModeTotalFee: TotalFee {
		let maxFee = expectedNormalModeLockFee
		let minFee = (maxFee - feeLocks.contingentLock).clamped
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

extension TransactionFee.FeeSummary {
	var networkFee: Decimal192 {
		totalExecutionCost + finalizationCost + storageExpansionCost
	}
}
