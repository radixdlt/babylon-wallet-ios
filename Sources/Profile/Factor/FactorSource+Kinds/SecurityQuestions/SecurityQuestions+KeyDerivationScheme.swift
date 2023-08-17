import Cryptography
import CryptoKit
import Prelude

// MARK: - VersionedSecurityQuestionBasedKeyDerivation
public protocol VersionedSecurityQuestionBasedKeyDerivation: VersionedKeyDerivation where Version == SecurityQuestionsFactorSource.KeyDerivationScheme.Version {
	static func deriveEncryptionKeysFrom(
		answersToQuestions: NonEmpty<OrderedSet<AnswerToSecurityQuestion>>
	) throws -> NonEmpty<[SymmetricKey]>

	static func validateConversionToEntropyOf(
		answer: String
	) throws -> SecurityQuestionAnswerAsEntropy

	static var minimumNumberOfQuestions: Int { get }
	static var minimumNumberCorrectAnswers: Int { get }
}

// MARK: - SecurityQuestionsFactorSource.KeyDerivationScheme
extension SecurityQuestionsFactorSource {
	/// The KDF algorithm used to derive the decryption key from a combination of answers to security questions.
	///
	/// N.B. Not to be confused with the much simpler password based Key Derivation used
	/// to encrypt ProfileSnapshot part of manual file export.
	public enum KeyDerivationScheme: Sendable, Hashable, VersionedAlgorithm {
		case version1
	}
}

extension SecurityQuestionsFactorSource.KeyDerivationScheme {
	public init(version: Version) {
		switch version {
		case .version1: self = .version1
		}
	}

	public static let `default`: Self = .version1

	private var schemeVersion: any VersionedSecurityQuestionBasedKeyDerivation.Type {
		switch self {
		case .version1: return Version1.self
		}
	}

	public var version: Version {
		schemeVersion.version
	}

	public var description: String {
		schemeVersion.description
	}

	public var minimumNumberOfQuestions: Int {
		schemeVersion.minimumNumberOfQuestions
	}

	public var minimumNumberCorrectAnswers: Int {
		schemeVersion.minimumNumberCorrectAnswers
	}

	public func validateConversionToEntropyOf(
		answer: String
	) throws -> SecurityQuestionAnswerAsEntropy {
		try schemeVersion.validateConversionToEntropyOf(answer: answer)
	}

	public func deriveEncryptionKeysFrom(
		answersToQuestions: NonEmpty<OrderedSet<AnswerToSecurityQuestion>>
	) throws -> NonEmpty<[SymmetricKey]> {
		try schemeVersion.deriveEncryptionKeysFrom(answersToQuestions: answersToQuestions)
	}
}

// MARK: - SecurityQuestionsFactorSource.KeyDerivationScheme.Version
extension SecurityQuestionsFactorSource.KeyDerivationScheme {
	public enum Version: Int, Sendable, Hashable, Codable {
		case version1 = 1
	}
}

// MARK: - SecurityQuestionsFactorSource.KeyDerivationScheme.Version1
extension SecurityQuestionsFactorSource.KeyDerivationScheme {
	/// A simple
	public struct Version1: VersionedSecurityQuestionBasedKeyDerivation {
		public static let version = Version.version1
		public static var description: String { "CAP23-3-of-4-questions-correct-common-separators-forbidden" }

		public static let minimumNumberOfQuestions = 4
		public static let minimumNumberCorrectAnswers = 3

		public static let forbiddenCharacters = CharacterSet
			.whitespacesAndNewlines
			.union(.characters(in: [
				".", // Rationale: Might be natural for some to end answers with a dot, but at a later point in time might be omitted.
				"!", // Rationale: Same as dot
				"?", // Rationale: Same as dot (also strange for an answer to a question to contain a question mark)
				"'", // Rationale: Feels like an unnessary risk for differences, sometimes some might omit apostrophe (U+0027)
				"\"", // Rationale: Same as apostrophe (this is "Quotation Mark" (U+0022))
				"‘", // Rationale: Same as apostrophe (this is "Left Single Quotation Mark" (U+2018))
				"’", // Rationale: Same as apostrophe (this is "Right Single Quotation Mark" (U+2019))
				"＇", // Rationale: Same as apostrophe (this is "Full Width Apostrophe" (U+FF07))
			]))

		private struct TrimmedAnswer: Sendable, Hashable {
			/// Non empty trimmed answer
			public let answer: NonEmptyString

			public init(nonTrimmed: NonEmptyString) throws {
				let trimmed = nonTrimmed.rawValue
					.lowercased()
					.removingCharacters(from: forbiddenCharacters)

				guard let nonEmptyTrimmed = NonEmptyString(rawValue: trimmed) else {
					struct AnswerIsEmptyWhenTrimmed: Swift.Error {}
					throw AnswerIsEmptyWhenTrimmed()
				}

				self.answer = nonEmptyTrimmed
			}
		}

		private static func trimmedAnswer(
			freeformAnswer: NonEmptyString
		) throws -> TrimmedAnswer {
			try .init(nonTrimmed: freeformAnswer)
		}

		/// `answer.lowercased().trimWhitespaceAndNewLine().utf8`
		private static func entropyFrom(
			freeformAnswer: TrimmedAnswer
		) throws -> NonEmpty<HexCodable> {
			let data = Data(
				freeformAnswer.answer.utf8
			)

			return NonEmpty<HexCodable>(rawValue: .init(data: data))!
		}

		public static func validateConversionToEntropyOf(
			answer: String
		) throws -> SecurityQuestionAnswerAsEntropy {
			guard let nonEmpty = NonEmptyString(answer) else {
				struct AnswerCannotBeEmpty: Error {}
				throw AnswerCannotBeEmpty()
			}
			return try .init(
				entropy: entropyFrom(
					freeformAnswer: trimmedAnswer(freeformAnswer: nonEmpty)
				)
			)
		}

		public static func deriveEncryptionKeysFrom(
			answersToQuestions: NonEmpty<OrderedSet<AnswerToSecurityQuestion>>
		) throws -> NonEmpty<[SymmetricKey]> {
			func _multiPartyKeyExchange(
				between privateKeys: NonEmpty<[Curve25519.KeyAgreement.PrivateKey]>
			) throws -> Curve25519.KeyAgreement.PublicKey {
				precondition(privateKeys.count >= 2)
				let first = privateKeys.first
				let rest = privateKeys.dropFirst()

				return try rest.reduce(first.publicKey) { publicKey, privateKey in
					try Curve25519.KeyAgreement.PublicKey(
						rawRepresentation: privateKey.sharedSecretFromKeyAgreement(with: publicKey)
					)
				}
			}

			func _multiPartyKeyExchangeBetweenAllCombinations(
				of privateKeys: NonEmpty<[Curve25519.KeyAgreement.PrivateKey]>,
				minus: Int = 1
			) throws -> NonEmpty<[Curve25519.KeyAgreement.PublicKey]> {
				precondition((privateKeys.count - minus) > 1)

				let privateKeyCombinations = privateKeys.rawValue.combinations(ofCount: privateKeys.count - minus).map {
					NonEmpty(rawValue: $0)!
				}

				return try NonEmpty(rawValue: privateKeyCombinations.map {
					try _multiPartyKeyExchange(between: $0)
				})!
			}

			func symmetricKeysFromMultiPartyKeyExchangeBetweenAllCombinations(
				of privateKeys: NonEmpty<[Curve25519.KeyAgreement.PrivateKey]>,
				minus: Int = 1
			) throws -> NonEmpty<[SymmetricKey]> {
				try _multiPartyKeyExchangeBetweenAllCombinations(
					of: privateKeys,
					minus: minus
				).map { SymmetricKey(data: $0.rawRepresentation) }
			}

			/// `PrivateKey(SHA(Question || Answer))`
			func kdfQuestionAnswer(
				answerToPersonalQuestion: AnswerToSecurityQuestion,
				maxAttempts: Int = 10
			) throws -> CryptoKit.Curve25519.KeyAgreement.PrivateKey {
				var attempts = 0
				while true {
					if attempts >= maxAttempts {
						break
					}
					defer { attempts += 1 }
					let answer = answerToPersonalQuestion.answer
					let question = answerToPersonalQuestion.question

					let inputKeyMaterial = SymmetricKey(data: answer.entropy.rawValue.data)
					let info = question.question.rawValue.data(using: .utf8)!
					let salt: Data = attempts.data // we use the counter as salt so that if we are extremely unlucky and PrivateKey init failed we get a chance at a new attempt by means of a different salt.
					let rawRepresentation = HKDF<SHA256>.deriveKey(
						inputKeyMaterial: inputKeyMaterial,
						salt: salt,
						info: info,
						outputByteCount: SHA256.byteCount
					)

					if let privateKey = try? CryptoKit.Curve25519.KeyAgreement.PrivateKey(rawRepresentation: rawRepresentation) {
						return privateKey
					}
				}
				struct FailedToDeriveKeyAfterMaxAttempts: Swift.Error {}
				throw FailedToDeriveKeyAfterMaxAttempts()
			}

			// N keys from answers to N questions
			let privateKeysFromAnswers = try answersToQuestions.map {
				try kdfQuestionAnswer(answerToPersonalQuestion: $0)
			}

			let encryptionKeys = try symmetricKeysFromMultiPartyKeyExchangeBetweenAllCombinations(
				of: privateKeysFromAnswers
			)

			return encryptionKeys
		}
	}
}

extension String {
	func removingAll(where condition: @escaping (Character) -> Bool) -> Self {
		var copy = self
		copy.removeAll(where: condition)
		return copy
	}

	func removingCharacters(from set: CharacterSet) -> Self {
		removingAll(where: { character in
			character.unicodeScalars.contains(where: { set.contains($0) })
		})
	}
}

extension CharacterSet {
	public static func characters(in collection: [Character]) -> Self {
		collection.map {
			Self(charactersIn: String($0))
		}.reduce(CharacterSet()) { $0.union($1) }
	}
}
