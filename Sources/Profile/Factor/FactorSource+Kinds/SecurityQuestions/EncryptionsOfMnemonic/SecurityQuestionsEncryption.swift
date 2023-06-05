import Cryptography
import Prelude

// MARK: - CAP23
public enum CAP23 {
	public static func deriveEncryptionKeysFrom(
		answersToQuestions: NonEmpty<OrderedSet<AnswerToSecurityQuestion>>
	) throws -> NonEmpty<[SymmetricKey]> {
		switch self {
		case .version1: return try EncryptMnemonicKDFCap23_Version1().deriveEncryptionKeysFrom(answersToQuestions: answersToQuestions)
		}
	}
}

// MARK: - Profile.EncryptionsOfMnemonic
public extension Profile {
	struct EncryptionsOfMnemonic: Sendable, Hashable, Codable {
		public let encryptions: NonEmpty<OrderedSet<HexCodable>>

		static func encrypt(
			mnemonicwithPassphrase: MnemonicWithPassphrase,
			withAnswersToQuestions answersToQuestion: NonEmpty<OrderedSet<SecurityQuestionAnswerToQuestionSimple>>,
			jsonEncoder: JSONEncoder,
		) throws -> Self {
			let plaintext = try jsonEncoder.encode(mnemonicwithPassphrase)
			let encryptionKeys = try kdf.deriveEncryptionKeysFrom(answersToQuestions: answersToQuestion)
			let encryptionsArray = try encryptionKeys.map {
				try HexCodable(data: encryptionScheme.encrypt(data: plaintext, key: $0))
			}
			return Self(
				keyDerivationFunctionUsed: kdf.embed(),
				encryptionSchemeUsed: encryptionScheme.embed(),
				encryptions: NonEmpty(rawValue: .init(encryptionsArray.rawValue))!
			)
		}

		func decrypt(
			withAnswersToQuestions answersToQuestion: NonEmpty<OrderedSet<SecurityQuestionAnswerToQuestionSimple>>,
			jsonDecoder: JSONDecoder
		) throws -> MnemonicWithPassphrase {
			let decryptionKeys = try keyDerivationFunctionUsed.deriveEncryptionKeysFrom(answersToQuestions: answersToQuestion)

			for decryptionKey in decryptionKeys {
				for encryptedMnemonic in self.encryptions {
					let decrypted: Data
					do {
						decrypted = try encryptionSchemeUsed.decrypt(data: encryptedMnemonic.data, key: decryptionKey)
					} catch {
						continue
					}
					let decoded = try jsonDecoder.decode(MnemonicWithPassphrase.self, from: decrypted)
					return decoded
				}
			}
			struct FailedToDecrypt: Swift.Error {}
			throw FailedToDecrypt()
		}
	}
}
