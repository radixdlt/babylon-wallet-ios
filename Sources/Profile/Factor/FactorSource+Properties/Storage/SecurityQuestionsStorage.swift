import Prelude

// MARK: - SecurityQuestionsStorage
public struct SecurityQuestionsStorage: Sendable, Hashable, Codable {
	public typealias Questions = NonEmpty<OrderedSet<NonEmptyString>>
	public let questions: Questions
	public let encryptionsOfMnemonic: EncryptionsOfMnemonic

	public init(
		questions: Questions,
		encryptionsOfMnemonic: EncryptionsOfMnemonic
	) {
		self.questions = questions
		self.encryptionsOfMnemonic = encryptionsOfMnemonic
	}
}

// MARK: - EncryptionsOfMnemonic
public struct EncryptionsOfMnemonic: Sendable, Hashable, Codable {
	// FIXME: Multifactor replace with `EncryptMnemonicKDF` type
	public let keyDerivationFunctionUsed: NonEmptyString
	// FIXME: Multifactor replace with `EncryptionSchemeSpecification` type
	public let encryptionSchemeUsed: NonEmptyString
	public let encryptions: NonEmpty<OrderedSet<HexCodable>>
}
