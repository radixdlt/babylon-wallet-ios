import Cryptography
import Prelude

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

// MARK: - CAP23
public enum CAP23 {
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

	public struct TrimmedAnswer: Sendable, Hashable {
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

	public static func trimmedAnswer(
		freeformAnswer: NonEmptyString
	) throws -> TrimmedAnswer {
		try .init(nonTrimmed: freeformAnswer)
	}

	/// `answer.lowercased().trimWhitespaceAndNewLine().utf8`
	public static func entropyFrom(
		freeformAnswer: TrimmedAnswer
	) throws -> NonEmpty<HexCodable> {
		let data = Data(
			freeformAnswer.answer.utf8
		)

		return NonEmpty<HexCodable>(rawValue: .init(data: data))!
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

// MARK: - SecurityQuestionsFactorSource.SealedMnemonic
extension SecurityQuestionsFactorSource {
	public struct SealedMnemonic: Sendable, Hashable, Codable {
		public let securityQuestions: NonEmpty<OrderedSet<SecurityQuestion>>
		public let encryptionScheme: EncryptionAES256GCM
		public let encryptions: NonEmpty<OrderedSet<HexCodable>>
	}
}

extension SecurityQuestionsFactorSource.SealedMnemonic {
	static func encrypt(
		mnemonic: Mnemonic,
		withAnswersToQuestions answersToQuestion: NonEmpty<OrderedSet<AnswerToSecurityQuestion>>,
		jsonEncoder: JSONEncoder,
		encryptionScheme: EncryptionAES256GCM = .default
	) throws -> Self {
		let plaintext = try jsonEncoder.encode(mnemonic)

		let encryptionKeys = try CAP23.deriveEncryptionKeysFrom(
			answersToQuestions: answersToQuestion
		)

		let encryptionsArray = try encryptionKeys.map {
			try HexCodable(
				data: encryptionScheme.encrypt(
					data: plaintext,
					key: $0
				)
			)
		}

		let encryptionsNonEmpty = NonEmpty<OrderedSet<HexCodable>>(
			rawValue: OrderedSet(
				uncheckedUniqueElements: encryptionsArray
			)
		)!

		let questions = NonEmpty<OrderedSet<SecurityQuestion>>(
			rawValue: OrderedSet(
				uncheckedUniqueElements: answersToQuestion.map(\.question)
			)
		)!

		return Self(
			securityQuestions: questions,
			encryptionScheme: encryptionScheme,
			encryptions: encryptionsNonEmpty
		)
	}

	func decrypt(
		withAnswersToQuestions answersToQuestion: NonEmpty<OrderedSet<AnswerToSecurityQuestion>>,
		jsonDecoder: JSONDecoder
	) throws -> Mnemonic {
		let decryptionKeys = try CAP23.deriveEncryptionKeysFrom(
			answersToQuestions: answersToQuestion
		)

		for decryptionKey in decryptionKeys {
			for encryptedMnemonic in self.encryptions {
				do {
					let decrypted = try encryptionScheme.decrypt(
						data: encryptedMnemonic.data,
						key: decryptionKey
					)
					return try jsonDecoder.decode(Mnemonic.self, from: decrypted)
				} catch {
					continue
				}
			}
		}

		// Failure
		struct FailedToDecrypt: Swift.Error {}
		throw FailedToDecrypt()
	}
}
