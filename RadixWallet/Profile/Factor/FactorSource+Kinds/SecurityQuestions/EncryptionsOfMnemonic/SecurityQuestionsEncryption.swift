// MARK: - SecurityQuestionsFactorSource.SealedMnemonic
extension SecurityQuestionsFactorSource {
	/// A mnemonic encrypted by answers to security questions
	public struct SealedMnemonic: Sendable, Hashable, Codable {
		public let securityQuestions: NonEmpty<OrderedSet<SecurityQuestion>>

		/// A versioned key derivation function algorithm used to produce a set
		/// of encryption keys from answers to `securityQuestions`.
		public let keyDerivationScheme: SecurityQuestionsFactorSource.KeyDerivationScheme

		/// The scheme used to encrypt the Security Questions factor source
		/// mnemonic using one combination of answers to questions, one of many.
		public let encryptionScheme: EncryptionScheme

		/// The N many encryptions of the mnemonic, where N corresponds to the number of derived keys
		/// from the `keyDerivationScheme`
		public let encryptions: NonEmpty<OrderedSet<HexCodable>>
	}
}

extension SecurityQuestionsFactorSource.SealedMnemonic {
	static func encrypt(
		mnemonic: Mnemonic,
		withAnswersToQuestions answersToQuestion: NonEmpty<OrderedSet<AnswerToSecurityQuestion>>,
		jsonEncoder: JSONEncoder,
		keyDerivationScheme: SecurityQuestionsFactorSource.KeyDerivationScheme = .default,
		encryptionScheme: EncryptionScheme = .default
	) throws -> Self {
		let plaintext = try jsonEncoder.encode(mnemonic)

		let encryptionKeys = try keyDerivationScheme.deriveEncryptionKeysFrom(
			answersToQuestions: answersToQuestion
		)

		let encryptionsArray = try encryptionKeys.map {
			try HexCodable(
				data: encryptionScheme.encrypt(
					data: plaintext,
					encryptionKey: $0
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
			keyDerivationScheme: keyDerivationScheme,
			encryptionScheme: encryptionScheme,
			encryptions: encryptionsNonEmpty
		)
	}

	func decrypt(
		withAnswersToQuestions answersToQuestion: NonEmpty<OrderedSet<AnswerToSecurityQuestion>>,
		jsonDecoder: JSONDecoder
	) throws -> Mnemonic {
		let decryptionKeys = try keyDerivationScheme.deriveEncryptionKeysFrom(
			answersToQuestions: answersToQuestion
		)

		for decryptionKey in decryptionKeys {
			for encryptedMnemonic in self.encryptions {
				do {
					let decrypted = try encryptionScheme.decrypt(
						data: encryptedMnemonic.data,
						decryptionKey: decryptionKey
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
