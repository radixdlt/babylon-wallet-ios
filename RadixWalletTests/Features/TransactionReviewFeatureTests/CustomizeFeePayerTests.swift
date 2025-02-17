@testable import Radix_Wallet_Dev
import Sargon
import XCTest

// MARK: - CustomizeFeePayerTests
@MainActor
final class CustomizeFeePayerTests: TestCase {
	func test_from_noFeePayer_toFeePayerSelected() async throws {
		let manifestStub = TransactionManifest.sample

		let notaryKey = Curve25519.Signing.PrivateKey()
		var transactionStub = ReviewedTransaction(
			transactionManifest: manifestStub,
			networkID: NetworkID.mainnet,
			feePayer: .success(nil),
			transactionFee: .nonContingentLockPaying,
			transactionSigners: .init(
				notaryPublicKey: notaryKey.publicKey,
				intentSigning: .notaryIsSignatory
			),
			signingFactors: [:],
			accountWithdraws: [:],
			accountDeposits: [:],
			isNonConforming: true
		)

		let state = CustomizeFees.State(
			reviewedTransaction: transactionStub,
			manifestSummary: try! manifestStub.summary,
			signingPurpose: .signTransaction(.internalManifest(.transfer))
		)

		let sut = TestStore(initialState: state) {
			CustomizeFees()
				.dependency(\.date, .constant(.init(timeIntervalSince1970: 0)))
				.dependency(\.factorSourcesClient.getSigningFactors) { request in
					try [.device: .init(rawValue: Set(request.signers.rawValue.map {
						try SigningFactor(
							factorSource: DeviceFactorSource.sample.asGeneral,
							signer: .init(factorInstancesRequiredToSign: $0.virtualHierarchicalDeterministicFactorInstances, of: $0)
						)
					}))!]
				}
		}

		let selectedFeePayer = FeePayerCandidate(account: .previewValue1, xrdBalance: 20)

		await sut.send(.view(.changeFeePayerTapped)) {
			$0.destination = .selectFeePayer(
				.init(
					reviewedTransaction: transactionStub,
					selectedFeePayer: nil,
					transactionFee: .nonContingentLockPaying
				)
			)
		}
		await sut.send(.destination(.presented(.selectFeePayer(.delegate(.selected(selectedFeePayer)))))) {
			$0.destination = nil
		}

		transactionStub.feePayer = .success(selectedFeePayer)
		let accountEntity = AccountOrPersona.account(selectedFeePayer.account)
		transactionStub.transactionSigners = .init(
			notaryPublicKey: notaryKey.publicKey,
			intentSigning: .intentSigners(.init(rawValue: [accountEntity])!)
		)

		let signingFactor = withDependencies {
			$0.date = .constant(.init(timeIntervalSince1970: 0))
		} operation: {
			accountEntity.signingFactor
		}

		transactionStub.signingFactors = [.device: .init(rawValue: [signingFactor])!]
		transactionStub.transactionFee.addLockFeeCost()
		transactionStub.transactionFee.updateSignaturesCost(1)
		transactionStub.transactionFee.updateNotarizingCost(notaryIsSignatory: false)

		await sut.receive(.internal(.updated(.success(transactionStub))), timeout: .seconds(1)) {
			$0.reviewedTransaction = transactionStub
		}
		await sut.receive(.delegate(.updated(transactionStub)))
	}
}

extension AccountOrPersona {
	var signingFactor: SigningFactor {
		try! SigningFactor(
			factorSource: DeviceFactorSource.sample.asGeneral,
			signer: .init(
				factorInstancesRequiredToSign: virtualHierarchicalDeterministicFactorInstances,
				of: self
			)
		)
	}
}
