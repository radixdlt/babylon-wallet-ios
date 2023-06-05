import CasePaths
import Cryptography
import Prelude

// MARK: - SecurityQuestionsFactorSource
public struct SecurityQuestionsFactorSource: FactorSourceProtocol {
	public var common: FactorSource.Common // We update `lastUsed`
	public let sealedMnemonic: SealedMnemonic

	internal init(
		common: FactorSource.Common,
		sealedMnemonic: SealedMnemonic
	) {
		precondition(common.id.factorSourceKind == Self.kind)
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
	public let answer: String
	public let question: SecurityQuestion

	public init(
		answer: String,
		to question: SecurityQuestion
	) {
		self.answer = answer
		self.question = question
	}
}

// MARK: - SecurityQuestionsFactorSource.SealedMnemonic
extension SecurityQuestionsFactorSource {
	public struct SealedMnemonic: Sendable, Hashable, Codable {
		public struct Encryption: Sendable, Hashable, Codable {
			public typealias Version = Tagged<(Self, version: ()), String>
			public let version: Version
			/// The encrypted mnemonic
			public let hexCodable: HexCodable
			public let publicKey: SLIP10.PublicKey
		}

		public let securityQuestions: OrderedSet<SecurityQuestion>
		public let encryptions: OrderedSet<Encryption>
	}
}

extension SecurityQuestionsFactorSource {
	internal static func encrypt(
		mnemonic: Mnemonic,
		with answersToQuestions: Set<AnswerToSecurityQuestion>
	) throws -> SealedMnemonic {
		try .init(
			securityQuestions: .init(validating: answersToQuestions.map(\.question)),
			encryptions: [] // FIXME: impl me
		)
	}

	public static func from(
		mnemonic: Mnemonic,
		answersToQuestions: Set<AnswerToSecurityQuestion>,
		addedOn: Date? = nil,
		lastUsedOn: Date? = nil
	) throws -> Self {
		@Dependency(\.date) var date

		let sealedMnemonic = try Self.encrypt(
			mnemonic: mnemonic,
			with: answersToQuestions
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
