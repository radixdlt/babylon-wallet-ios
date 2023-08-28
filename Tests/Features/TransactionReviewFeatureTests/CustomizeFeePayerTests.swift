import Cryptography
import EngineKit
@testable import FactorSourcesClient
import FeatureTestingPrelude
@testable import Profile
import TransactionClient
@testable import TransactionReviewFeature

// MARK: - CustomizeFeePayerTests
@MainActor
final class CustomizeFeePayerTests: TestCase {
	func test_from_noFeePayer_toFeePayerSelected() async throws {
		let manifestStub = try TransactionManifest(instructions: .fromInstructions(instructions: [], networkId: NetworkID.enkinet.rawValue), blobs: [])
		let notaryKey = Curve25519.Signing.PrivateKey()
		var transactionStub = ReviewedTransaction(
			feePayerSelection: .init(
				selected: nil,
				candidates: .init(.init(account: .previewValue0, xrdBalance: 10)),
				transactionFee: .nonContingentLockPaying
			),
			networkId: NetworkID.enkinet,
			transaction: .nonConforming,
			transactionSigners: .init(notaryPublicKey: notaryKey.publicKey, intentSigning: .notaryIsSignatory),
			signingFactors: [:]
		)

		let state = CustomizeFees.State(
			reviewedTransaction: transactionStub,
			manifest: manifestStub,
			signingPurpose: .signTransaction(.internalManifest(.transfer))
		)
		let sut = TestStore(initialState: state, reducer: CustomizeFees()) {
			$0.factorSourcesClient.getSigningFactors = { request in
				try [.device: .init(rawValue: Set(request.signers.rawValue.map {
					try SigningFactor(
						factorSource: .device(.babylon(mnemonicWithPassphrase: .testValue)),
						signer: .init(factorInstancesRequiredToSign: $0.virtualHierarchicalDeterministicFactorInstances, of: $0)
					)
				}))!]
			}
			$0.date = .constant(.now)
		}

		let selectedFeePayer = FeePayerCandidate(account: .previewValue1, xrdBalance: 20)

		await sut.send(.view(.changeFeePayerTapped)) {
			$0.destination = .selectFeePayer(.init(feePayerSelection: transactionStub.feePayerSelection))
		}
		await sut.send(.child(.destination(.presented(.selectFeePayer(.delegate(.selected(selectedFeePayer))))))) {
			$0.destination = nil
		}

		transactionStub.feePayerSelection.selected = selectedFeePayer
		let accountEntity = EntityPotentiallyVirtual.account(selectedFeePayer.account)
		transactionStub.transactionSigners = .init(notaryPublicKey: notaryKey.publicKey, intentSigning: .intentSigners(.init(rawValue: [accountEntity])!))

		let signingFactor = withDependencies {
			$0.date = .constant(.now)
		} operation: {
			accountEntity.signinFactor
		}

		transactionStub.signingFactors = [.device: .init(rawValue: [signingFactor])!]
		transactionStub.feePayerSelection.transactionFee.addLockFeeCost()
		transactionStub.feePayerSelection.transactionFee.updateSignaturesCost(1)
		transactionStub.feePayerSelection.transactionFee.updateNotarizingCost(notaryIsSignatory: false)

		await sut.receive(.internal(.updated(.success(transactionStub))), timeout: .seconds(1)) {
			$0.reviewedTransaction = transactionStub
		}
	}
}

extension EntityPotentiallyVirtual {
	var signinFactor: SigningFactor {
		try! SigningFactor(
			factorSource: .device(.babylon(mnemonicWithPassphrase: .testValue)),
			signer: .init(factorInstancesRequiredToSign: virtualHierarchicalDeterministicFactorInstances, of: self)
		)
	}
}

// MARK: - TransactioManifesStub
final class TransactioManifesStub: TransactionManifestProtocol, Hashable, Sendable {
	func hash(into hasher: inout Hasher) {
		hasher.combine(accountsRequiringAuthStub)
	}

	let accountsRequiringAuthStub: [EngineToolkit.Address]

	init(accountsRequiringAuthStub: [EngineToolkit.Address] = []) {
		self.accountsRequiringAuthStub = accountsRequiringAuthStub
	}

	func accountsDepositedInto() -> [EngineToolkit.Address] {
		fatalError()
	}

	func accountsRequiringAuth() -> [EngineToolkit.Address] {
		[]
	}

	func accountsWithdrawnFrom() -> [EngineToolkit.Address] {
		fatalError()
	}

	func analyzeExecution(transactionReceipt: [UInt8]) throws -> EngineToolkit.ExecutionAnalysis {
		fatalError()
	}

	func blobs() -> [[UInt8]] {
		fatalError()
	}

	func extractAddresses() -> [EngineToolkit.EntityType: [EngineToolkit.Address]] {
		fatalError()
	}

	func identitiesRequiringAuth() -> [EngineToolkit.Address] {
		fatalError()
	}

	func instructions() -> EngineToolkit.Instructions {
		fatalError()
	}

	func modify(modifications: EngineToolkit.TransactionManifestModifications) throws -> EngineToolkit.TransactionManifest {
		fatalError()
	}

	func staticallyValidate() throws {
		fatalError()
	}

	static func == (lhs: TransactioManifesStub, rhs: TransactioManifesStub) -> Bool {
		lhs.accountsRequiringAuthStub == rhs.accountsRequiringAuthStub
	}
}
