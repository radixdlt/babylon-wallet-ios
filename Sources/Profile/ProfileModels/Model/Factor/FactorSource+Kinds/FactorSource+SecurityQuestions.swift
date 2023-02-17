import Cryptography
import Prelude

public extension FactorSource {
	static func securityQuestions(
		mnemonic unencryptedMnemonic: Mnemonic,
		withAnswersToQuestions answersToQuestion: NonEmpty<OrderedSet<SecurityQuestionAnswerToQuestionSimple>>,
		kdf: EncryptMnemonicKDF,
		encryptionScheme: EncryptionSchemeSpecification
	) throws -> Self {
		// User is not allowed to specify any passphrase for the mnemonic encrypted
		// with the security questions factor source.
		let passphrase = ""

		let storage = try SecurityQuestionsStorage.encrypt(
			mnemonicwithPassphrase: .init(mnemonic: unencryptedMnemonic, passphrase: passphrase),
			withAnswersToQuestions: answersToQuestion,
			jsonEncoder: .init(),
			kdf: kdf,
			encryptionScheme: encryptionScheme
		)

		return try Self(
			kind: .securityQuestions,
			id: id(fromRoot: unencryptedMnemonic.hdRoot(passphrase: passphrase)),
			hint: "#\(answersToQuestion.count) questions",
			parameters: .default,
			storage: .forSecurityQuestions(storage)
		)
	}

	func securityQuestionsStorage() throws -> SecurityQuestionsStorage {
		guard kind == .securityQuestions else {
			struct NotSecurityQuestionsKind: Swift.Error {}
			throw NotSecurityQuestionsKind()
		}
		guard let storage else {
			struct IncorrectImplementationNoStorageForSecurityQuestionsButExpectedToAlwaysBePresent: Swift.Error {}
			throw IncorrectImplementationNoStorageForSecurityQuestionsButExpectedToAlwaysBePresent()
		}
		return try storage.securityQuestions()
	}

	func decryptSecurityQuestions(
		with answersToQuestions: NonEmpty<OrderedSet<SecurityQuestionAnswerToQuestionSimple>>
	) throws -> MnemonicWithPassphrase {
		assert(kind == .securityQuestions)
		let storage = try securityQuestionsStorage()
		let mnemonicWithPassphrase = try storage.decrypt(withAnswersToQuestions: answersToQuestions)
		let id = try FactorSource.id(fromRoot: mnemonicWithPassphrase.hdRoot())
		guard id == self.id else {
			struct FailedToDecryptMnemonicProtectedBySecurityQuestionsIDMismatchesExpected: Swift.Error {}
			throw FailedToDecryptMnemonicProtectedBySecurityQuestionsIDMismatchesExpected()
		}
		return mnemonicWithPassphrase
	}
}

extension FactorSource.Storage {
	var securityQuestionsStorage: SecurityQuestionsStorage? {
		switch self {
		case let .forSecurityQuestions(securityQuestionsStorage): return securityQuestionsStorage
		}
	}

	func securityQuestions() throws -> SecurityQuestionsStorage {
		guard let securityQuestionsStorage else {
			struct NotStorageForSecurityQuestions: Swift.Error {}
			throw NotStorageForSecurityQuestions()
		}
		return securityQuestionsStorage
	}
}

// MARK: - SecurityQuestionsStorage
public struct SecurityQuestionsStorage: Sendable, Hashable, Codable {
	public typealias Questions = NonEmpty<OrderedSet<SecurityQuestionAnswerToQuestionSimple.Question>>
	public let questions: Questions
	public let encryptionsOfMnemonic: EncryptionsOfMnemonic

	public init(
		questions: Questions,
		encryptionsOfMnemonic: EncryptionsOfMnemonic
	) {
		self.questions = questions
		self.encryptionsOfMnemonic = encryptionsOfMnemonic
	}

	static func encrypt(
		mnemonicwithPassphrase: MnemonicWithPassphrase,
		withAnswersToQuestions answersToQuestions: NonEmpty<OrderedSet<SecurityQuestionAnswerToQuestionSimple>>,
		jsonEncoder: JSONEncoder,
		kdf: EncryptMnemonicKDF,
		encryptionScheme: EncryptionSchemeSpecification
	) throws -> Self {
		let questions = NonEmpty(rawValue: OrderedSet(answersToQuestions.map(\.question)))!

		return try Self(
			questions: questions,
			encryptionsOfMnemonic: .encrypt(
				mnemonicwithPassphrase: mnemonicwithPassphrase,
				withAnswersToQuestions: answersToQuestions,
				jsonEncoder: jsonEncoder,
				kdf: kdf,
				encryptionScheme: encryptionScheme
			)
		)
	}

	func decrypt(
		withAnswersToQuestions answersToQuestions: NonEmpty<OrderedSet<SecurityQuestionAnswerToQuestionSimple>>,
		jsonDecoder: JSONDecoder = .init()
	) throws -> MnemonicWithPassphrase {
		let providedQuestions = Set(answersToQuestions.map(\.question).rawValue)
		let expectedQuestions = Set(self.questions.rawValue.elements)
		guard providedQuestions == expectedQuestions else {
			struct WrongQuestionsAnswered: Swift.Error {}
			throw WrongQuestionsAnswered()
		}
		let mnemonicWithPassphrase = try encryptionsOfMnemonic.decrypt(
			withAnswersToQuestions: answersToQuestions,
			jsonDecoder: jsonDecoder
		)
		return mnemonicWithPassphrase
	}
}

import CryptoKit

// MARK: - EncryptionSchemeVersionTag
public enum EncryptionSchemeVersionTag: Hashable {}
public typealias EncryptionSchemeVersion = Tagged<EncryptionSchemeVersionTag, String>

// MARK: - EncryptionSchemeAlgorithmTag
public enum EncryptionSchemeAlgorithmTag: Hashable {}
public typealias EncryptionSchemeAlgorithm = Tagged<EncryptionSchemeAlgorithmTag, String>

// MARK: - _EncryptionSchemeSpecificationProtocol
internal protocol _EncryptionSchemeSpecificationProtocol {
	var algorithm: EncryptionSchemeAlgorithm { get }
	var version: EncryptionSchemeVersion { get }
	func embed() -> EncryptionSchemeSpecification
}

// MARK: - _EncryptionProtocol
internal protocol _EncryptionProtocol {
	func encrypt(data: Data, key: SymmetricKey) throws -> Data
	func decrypt(data: Data, key: SymmetricKey) throws -> Data
}

// MARK: - AES256GCMScheme
public enum AES256GCMScheme: String, Sendable, _EncryptionProtocol, _EncryptionSchemeSpecificationProtocol, Codable {
	public static let algorithm: EncryptionSchemeAlgorithm = "aesGCM256"
	public var algorithm: EncryptionSchemeAlgorithm { Self.algorithm }
	public var version: EncryptionSchemeVersion { .init(rawValue: rawValue) }

	case version1
	public static let `default`: Self = .version1

	func embed() -> EncryptionSchemeSpecification {
		.aes256GCM(.version1)
	}

	public func encrypt(data: Data, key: SymmetricKey) throws -> Data {
		switch self {
		case .version1: return try EncryptionAES256GCM_Version1().encrypt(data: data, key: key)
		}
	}

	public func decrypt(data: Data, key: SymmetricKey) throws -> Data {
		switch self {
		case .version1: return try EncryptionAES256GCM_Version1().decrypt(data: data, key: key)
		}
	}
}

// MARK: - EncryptionSchemeSpecification
public enum EncryptionSchemeSpecification: _EncryptionProtocol, _EncryptionSchemeSpecificationProtocol, Sendable, Hashable, Codable {
	public static let `default`: Self = .aes256GCM(.default)
	case aes256GCM(AES256GCMScheme)

	private enum CodingKeys: String, CodingKey {
		case algorithm, versionedScheme
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let algorithm = try container.decode(EncryptionSchemeAlgorithm.self, forKey: .algorithm)
		switch algorithm {
		case AES256GCMScheme.algorithm:
			self = try .aes256GCM(container.decode(AES256GCMScheme.self, forKey: .versionedScheme))
		default:
			struct UnknownEncryptionScheme: Swift.Error {}
			throw UnknownEncryptionScheme()
		}
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		switch self {
		case let .aes256GCM(versioned):
			try container.encode(AES256GCMScheme.algorithm, forKey: .algorithm)
			try container.encode(versioned.version, forKey: .versionedScheme)
		}
	}
}

public extension EncryptionSchemeSpecification {
	func embed() -> Self {
		self
	}

	var version: EncryptionSchemeVersion {
		switch self {
		case let .aes256GCM(value): return value.version
		}
	}

	var algorithm: EncryptionSchemeAlgorithm {
		switch self {
		case let .aes256GCM(value): return value.algorithm
		}
	}

	func encrypt(data: Data, key: SymmetricKey) throws -> Data {
		switch self {
		case let .aes256GCM(enc): return try enc.encrypt(data: data, key: key)
		}
	}

	func decrypt(data: Data, key: SymmetricKey) throws -> Data {
		switch self {
		case let .aes256GCM(enc): return try enc.decrypt(data: data, key: key)
		}
	}
}

// MARK: - EncryptionAES256GCM_Version1
public struct EncryptionAES256GCM_Version1: _EncryptionProtocol {
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

// MARK: - KDFVersionTag
public enum KDFVersionTag: Hashable {}
public typealias KDFVersion = Tagged<KDFVersionTag, String>

// MARK: - KDFAlgorithmTag
public enum KDFAlgorithmTag: Hashable {}
public typealias KDFAlgorithm = Tagged<KDFAlgorithmTag, String>

// MARK: - _EncryptMnemonicKDFSpecificationProtocol
internal protocol _EncryptMnemonicKDFSpecificationProtocol: Sendable {
	var version: KDFVersion { get }
	var algorithm: KDFAlgorithm { get }
	func embed() -> EncryptMnemonicKDF
}

// MARK: - _EncryptMnemonicKDFProtocol
internal protocol _EncryptMnemonicKDFProtocol: Sendable {
	func deriveEncryptionKeysFrom(
		answersToQuestions: NonEmpty<OrderedSet<SecurityQuestionAnswerToQuestionSimple>>
	) throws -> NonEmpty<[SymmetricKey]>
}

// MARK: - EncryptMnemonicKDF
public enum EncryptMnemonicKDF: _EncryptMnemonicKDFSpecificationProtocol, _EncryptMnemonicKDFProtocol, Codable, Hashable, Sendable {
	public static let `default`: Self = .cap23(.default)
	case cap23(EncryptMnemonicKDFCap23Scheme)
}

// MARK: - EncryptMnemonicKDFCap23Scheme
public enum EncryptMnemonicKDFCap23Scheme: String, Sendable, _EncryptMnemonicKDFSpecificationProtocol, _EncryptMnemonicKDFProtocol, Codable, Hashable {
	public static let algorithm: KDFAlgorithm = "encryptMnemonicKDFCAP23"
	public var algorithm: KDFAlgorithm { Self.algorithm }
	public var version: KDFVersion { .init(rawValue: rawValue) }

	case version1
	public static let `default`: Self = .version1

	func embed() -> EncryptMnemonicKDF {
		.cap23(self)
	}

	func deriveEncryptionKeysFrom(
		answersToQuestions: NonEmpty<OrderedSet<SecurityQuestionAnswerToQuestionSimple>>
	) throws -> NonEmpty<[SymmetricKey]> {
		switch self {
		case .version1: return try EncryptMnemonicKDFCap23_Version1().deriveEncryptionKeysFrom(answersToQuestions: answersToQuestions)
		}
	}
}

public extension EncryptMnemonicKDF {
	private enum CodingKeys: String, CodingKey {
		case algorithm, versionedScheme
	}

	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let algorithm = try container.decode(KDFAlgorithm.self, forKey: .algorithm)
		switch algorithm {
		case EncryptMnemonicKDFCap23Scheme.algorithm:
			self = try .cap23(container.decode(EncryptMnemonicKDFCap23Scheme.self, forKey: .versionedScheme))
		default:
			struct UnknownEncryptionScheme: Swift.Error {}
			throw UnknownEncryptionScheme()
		}
	}

	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		switch self {
		case let .cap23(versioned):
			try container.encode(EncryptMnemonicKDFCap23Scheme.algorithm, forKey: .algorithm)
			try container.encode(versioned.version, forKey: .versionedScheme)
		}
	}

	var version: KDFVersion {
		switch self {
		case let .cap23(kdf): return kdf.version
		}
	}

	var algorithm: KDFAlgorithm {
		switch self {
		case let .cap23(kdf): return kdf.algorithm
		}
	}

	func deriveEncryptionKeysFrom(
		answersToQuestions: NonEmpty<OrderedSet<SecurityQuestionAnswerToQuestionSimple>>
	) throws -> NonEmpty<[SymmetricKey]> {
		switch self {
		case let .cap23(kdf): return try kdf.deriveEncryptionKeysFrom(answersToQuestions: answersToQuestions)
		}
	}

	func embed() -> EncryptMnemonicKDF {
		self
	}
}

// MARK: - EncryptMnemonicKDFCap23_Version1
public struct EncryptMnemonicKDFCap23_Version1: _EncryptMnemonicKDFProtocol {
	public init() {}
	public func deriveEncryptionKeysFrom(
		answersToQuestions: NonEmpty<OrderedSet<SecurityQuestionAnswerToQuestionSimple>>
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
			answerToPersonalQuestion: SecurityQuestionAnswerToQuestionSimple,
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

				let inputKeyMaterial = SymmetricKey(data: answer.entropy.rawValue)
				let info = question.display.rawValue.data(using: .utf8)!
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

// MARK: - EncryptionsOfMnemonic
public struct EncryptionsOfMnemonic: Sendable, Hashable, Codable {
	public let keyDerivationFunctionUsed: EncryptMnemonicKDF
	public let encryptionSchemeUsed: EncryptionSchemeSpecification
	public let encryptions: NonEmpty<OrderedSet<HexCodable>>

	static func encrypt(
		mnemonicwithPassphrase: MnemonicWithPassphrase,
		withAnswersToQuestions answersToQuestion: NonEmpty<OrderedSet<SecurityQuestionAnswerToQuestionSimple>>,
		jsonEncoder: JSONEncoder,
		kdf: EncryptMnemonicKDF,
		encryptionScheme: EncryptionSchemeSpecification
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

#if DEBUG
struct AnswerQuestionCountDiscrepancy: Swift.Error {}
public extension NonEmpty where Collection == OrderedSet<SecurityQuestionAnswerToQuestionSimple> {
	init(
		questions questionsMaybeEmpty: [String],
		answers answersMaybeEmpty: [String]
	) throws {
		let questions = questionsMaybeEmpty.compactMap { NonEmpty<String>.init(rawValue: $0) }
		let answers = answersMaybeEmpty.compactMap { NonEmpty<String>.init(rawValue: $0) }
		guard answers.count == questions.count else {
			throw AnswerQuestionCountDiscrepancy()
		}
		let answersToQuestionsArray = zip(questions, answers).map {
			SecurityQuestionAnswerToQuestionSimple.answer($0.1, to: $0.0)
		}
		guard let answersToQuestions = NonEmpty<OrderedSet<SecurityQuestionAnswerToQuestionSimple>>(rawValue: .init(answersToQuestionsArray)) else {
			fatalError("discrepancy should not have been empty")
		}
		self = answersToQuestions
	}
}

public extension FactorSource {
	func decryptSecurityQuestions(
		answers: [String]
	) throws -> MnemonicWithPassphrase {
		let questions = try self.securityQuestionsStorage().questions.rawValue.elements
		return try self.decryptSecurityQuestions(with: .init(questions: questions.map(\.display.rawValue), answers: answers))
	}

	static func securityQuestions(
		mnemonic unencryptedMnemonic: Mnemonic,
		questions: [String],
		answers: [String]
	) throws -> Self {
		try Self.securityQuestions(
			mnemonic: unencryptedMnemonic,
			withAnswersToQuestions: .init(questions: questions, answers: answers),
			kdf: .default,
			encryptionScheme: .default
		)
	}
}
#endif
