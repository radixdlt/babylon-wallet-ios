import CasePaths
import Cryptography
import Prelude

// MARK: - SecurityQuestionsFactorSource
public struct SecurityQuestionsFactorSource: FactorSourceProtocol {
	public typealias ID = FactorSourceID.FromHash
	public let id: ID
	public var common: FactorSource.Common // We update `lastUsed`
	public let sealedMnemonic: SealedMnemonic

	internal init(
		id: ID,
		common: FactorSource.Common,
		sealedMnemonic: SealedMnemonic
	) {
		precondition(id.kind == Self.kind)
		self.id = id
		self.common = common
		self.sealedMnemonic = sealedMnemonic
	}
}

extension SecurityQuestionsFactorSource {
	/// Kind of factor source
	public static let kind: FactorSourceKind = .securityQuestions
	public static let casePath: CasePath<FactorSource, Self> = /FactorSource.securityQuestions
}

// MARK: - SecurityQuestion
public struct SecurityQuestion: Sendable, Hashable, Codable, Identifiable {
	public typealias ID = Tagged<(Self, id: ()), UInt>
	public typealias Version = Tagged<(Self, version: ()), UInt>
	public enum Kind: String, Sendable, Hashable, Codable {
		case freeform
	}

	public let id: ID
	public let version: Version
	public let kind: Kind
	public let question: NonEmptyString

	public init(
		id: ID,
		question: NonEmptyString,
		version: Version = 1,
		kind: Kind = .freeform
	) {
		self.id = id
		self.version = version
		self.kind = kind
		self.question = question
	}
}

// MARK: - AnswerToSecurityQuestion
public struct AnswerToSecurityQuestion: Sendable, Hashable, Codable {
	public struct Answer: Sendable, Hashable, Codable {
		public let entropy: NonEmpty<HexCodable>
		private init(entropy: NonEmpty<HexCodable>) {
			self.entropy = entropy
		}

		public static func from(_ answer: NonEmptyString) -> Self {
			.init(
				entropy: CAP23.entropyFrom(freeformAnswer: answer)
			)
		}
	}

	public let question: SecurityQuestion
	public let answer: Answer

	public init(
		answer: Answer,
		to question: SecurityQuestion
	) {
		self.answer = answer
		self.question = question
	}
}

// MARK: - SecurityQuestionsFactorSource.SealedMnemonic
extension SecurityQuestionsFactorSource {
	public struct SealedMnemonic: Sendable, Hashable, Codable {
		public let securityQuestions: NonEmpty<OrderedSet<SecurityQuestion>>
		public let encryptions: NonEmpty<OrderedSet<HexCodable>>
	}
}

extension SecurityQuestionsFactorSource {
	public func decrypt(
		answersToQuestions: NonEmpty<OrderedSet<AnswerToSecurityQuestion>>
	) throws -> Mnemonic {
		@Dependency(\.jsonDecoder) var jsonDecoder
		return try sealedMnemonic.decrypt(
			withAnswersToQuestions: answersToQuestions,
			jsonDecoder: jsonDecoder()
		)
	}

	public static func from(
		mnemonic: Mnemonic,
		answersToQuestions: NonEmpty<OrderedSet<AnswerToSecurityQuestion>>,
		addedOn: Date? = nil,
		lastUsedOn: Date? = nil
	) throws -> Self {
		@Dependency(\.date) var date
		@Dependency(\.jsonEncoder) var jsonEncoder

		let sealedMnemonic = try SealedMnemonic.encrypt(
			mnemonic: mnemonic,
			withAnswersToQuestions: answersToQuestions,
			jsonEncoder: jsonEncoder()
		)

		return try Self(
			common: .from(
				factorSourceKind: Self.kind,
				hdRoot: mnemonic.hdRoot(),
				addedOn: addedOn ?? date(),
				lastUsedOn: lastUsedOn ?? date()
			),
			sealedMnemonic: sealedMnemonic
		)
	}
}
