import Cryptography
import Prelude

// MARK: - CAP23
public enum CAP23 {
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

extension SecurityQuestionsFactorSource.SealedMnemonic {
	static func encrypt(
		mnemonicwithPassphrase: MnemonicWithPassphrase,
		withAnswersToQuestions answersToQuestion: NonEmpty<OrderedSet<AnswerToSecurityQuestion>>,
		jsonEncoder: JSONEncoder
	) throws -> NonEmpty<Set<HexCodable>> {
		let plaintext = try jsonEncoder.encode(mnemonicwithPassphrase)
//			let encryptionKeys = try kdf.deriveEncryptionKeysFrom(answersToQuestions: answersToQuestion)
//			let encryptionsArray = try encryptionKeys.map {
//				try HexCodable(data: encryptionScheme.encrypt(data: plaintext, key: $0))
//			}
//			return Self(
//				keyDerivationFunctionUsed: kdf.embed(),
//				encryptionSchemeUsed: encryptionScheme.embed(),
//				encryptions: NonEmpty(rawValue: .init(encryptionsArray.rawValue))!
//			)
		fatalError()
	}

	func decrypt(
		withAnswersToQuestions answersToQuestion: NonEmpty<OrderedSet<AnswerToSecurityQuestion>>,
		jsonDecoder: JSONDecoder
	) throws -> MnemonicWithPassphrase {
//			let decryptionKeys = try keyDerivationFunctionUsed.deriveEncryptionKeysFrom(answersToQuestions: answersToQuestion)
//
//			for decryptionKey in decryptionKeys {
//				for encryptedMnemonic in self.encryptions {
//					let decrypted: Data
//					do {
//						decrypted = try encryptionSchemeUsed.decrypt(data: encryptedMnemonic.data, key: decryptionKey)
//					} catch {
//						continue
//					}
//					let decoded = try jsonDecoder.decode(MnemonicWithPassphrase.self, from: decrypted)
//					return decoded
//				}
//			}
//			struct FailedToDecrypt: Swift.Error {}
//			throw FailedToDecrypt()
		fatalError()
	}
}
