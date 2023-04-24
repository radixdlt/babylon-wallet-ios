import ClientPrelude
import EngineToolkitClient

// MARK: - TransactionClient
public struct TransactionClient: Sendable, DependencyKey {
	public var convertManifestInstructionsToJSONIfItWasString: ConvertManifestInstructionsToJSONIfItWasString
	public var addLockFeeInstructionToManifest: AddLockFeeInstructionToManifest
	public var addGuaranteesToManifest: AddGuaranteesToManifest
	public var getTransactionReview: GetTransactionReview
}

// MARK: TransactionClient.SignAndSubmitTransaction
extension TransactionClient {
	public typealias AddLockFeeInstructionToManifest = @Sendable (TransactionManifest, _ fee: BigDecimal) async throws -> AddFeeToManifestOutcome
	public typealias AddGuaranteesToManifest = @Sendable (TransactionManifest, [Guarantee]) async throws -> TransactionManifest
	public typealias ConvertManifestInstructionsToJSONIfItWasString = @Sendable (TransactionManifest) async throws -> JSONInstructionsTransactionManifest
	public typealias GetTransactionReview = @Sendable (ManifestReviewRequest) async -> TransactionReviewResult
}

public typealias TransactionReviewResult = Swift.Result<TransactionToReview, TransactionFailure>

extension DependencyValues {
	public var transactionClient: TransactionClient {
		get { self[TransactionClient.self] }
		set { self[TransactionClient.self] = newValue }
	}
}

public typealias SelectNotary = @Sendable (NonEmpty<OrderedSet<Profile.Network.Account>>) async -> Profile.Network.Account

// MARK: - TransactionClient.Guarantee
extension TransactionClient {
	public struct Guarantee: Sendable, Hashable {
		public var amount: BigDecimal
		public var instructionIndex: UInt32
		public var resourceAddress: ResourceAddress

		public init(amount: BigDecimal, instructionIndex: UInt32, resourceAddress: ResourceAddress) {
			self.amount = amount
			self.instructionIndex = instructionIndex
			self.resourceAddress = resourceAddress
		}
	}
}

// MARK: - ManifestReviewRequest
// Duplicated for now, very similar to SignManifestRequest
public struct ManifestReviewRequest: Sendable {
	public let manifestToSign: TransactionManifest
	public let feeToAdd: BigDecimal
	public let makeTransactionHeaderInput: MakeTransactionHeaderInput
	public let selectNotary: SelectNotary

	public init(
		manifestToSign: TransactionManifest,
		makeTransactionHeaderInput: MakeTransactionHeaderInput = .default,
		feeToAdd: BigDecimal,
		selectNotary: @escaping SelectNotary = { $0.first }
	) {
		self.manifestToSign = manifestToSign
		self.feeToAdd = feeToAdd
		self.makeTransactionHeaderInput = makeTransactionHeaderInput
		self.selectNotary = selectNotary
	}
}

// MARK: - FeePayerCandiate
public struct FeePayerCandiate: Sendable, Hashable {
	public let account: Profile.Network.Account
	public let xrdBalance: BigDecimal
}

// MARK: - AddFeeToManifestOutcome
public enum AddFeeToManifestOutcome: Sendable, Equatable {
	case includesLockFee(TransactionManifest, feeAdded: BigDecimal)
	case excludesLockFee(TransactionManifest, feePayerCandidates: Set<FeePayerCandiate>, feeNotYetAdded: BigDecimal)
}

// MARK: - TransactionToReview
public struct TransactionToReview: Sendable, Equatable {
	public let analyzedManifestToReview: AnalyzeManifestWithPreviewContextResponse
	public let addFeeToManifestOutcome: AddFeeToManifestOutcome
	public let networkID: NetworkID
}
