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
		.init(collection.map(String.init).joined(""))
	}
}

// MARK: - CAP23
public enum CAP23 {
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

	/// `answer.lowercased().trimWhitespaceAndNewLine().utf8`
	public static func entropyFrom(
		freeformAnswer: NonEmptyString
	) -> NonEmpty<HexCodable> {
		let data = Data(
			freeformAnswer.rawValue
				.lowercased()
				.removingCharacters(from: forbiddenCharacters)
				.utf8
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

// MARK: - EncryptionAES256GCM_Version1
public struct EncryptionAES256GCM_Version1 {
	public init() {}
	public func decrypt(data: Data, key: SymmetricKey) throws -> Data {
		let sealedBox = try AES.GCM.SealedBox(combined: data)
		return try AES.GCM.open(sealedBox, using: key)
	}

	public func encrypt(data: Data, key: SymmetricKey) throws -> Data {
		let sealedBox = try AES.GCM.seal(data, using: key)
		guard let combined = sealedBox.combined else {
			struct SealedBoxContainsNoCombinedCipher: Swift.Error {}
			throw SealedBoxContainsNoCombinedCipher()
		}
		return combined
	}
}

extension SecurityQuestionsFactorSource.SealedMnemonic {
	static func encrypt(
		mnemonic: Mnemonic,
		withAnswersToQuestions answersToQuestion: NonEmpty<OrderedSet<AnswerToSecurityQuestion>>,
		jsonEncoder: JSONEncoder
	) throws -> Self {
		let plaintext = try jsonEncoder.encode(mnemonic)
		let encryptionKeys = try CAP23.deriveEncryptionKeysFrom(answersToQuestions: answersToQuestion)
		let encryptionScheme = EncryptionAES256GCM_Version1()
		let encryptionsArray = try encryptionKeys.map {
			try HexCodable(data: encryptionScheme.encrypt(data: plaintext, key: $0))
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
			encryptions: encryptionsNonEmpty
		)
	}

	func decrypt(
		withAnswersToQuestions answersToQuestion: NonEmpty<OrderedSet<AnswerToSecurityQuestion>>,
		jsonDecoder: JSONDecoder
	) throws -> Mnemonic {
		let decryptionKeys = try CAP23.deriveEncryptionKeysFrom(answersToQuestions: answersToQuestion)
		let encryptionScheme = EncryptionAES256GCM_Version1()
		for decryptionKey in decryptionKeys {
			for encryptedMnemonic in self.encryptions {
				let decrypted: Data
				do {
					decrypted = try encryptionScheme.decrypt(
						data: encryptedMnemonic.data,
						key: decryptionKey
					)
				} catch {
					continue
				}
				let decoded = try jsonDecoder.decode(Mnemonic.self, from: decrypted)
				return decoded
			}
		}
		struct FailedToDecrypt: Swift.Error {}
		throw FailedToDecrypt()
	}
}
