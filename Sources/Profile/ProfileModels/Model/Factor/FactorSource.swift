import Cryptography
import Prelude

// MARK: - FactorSource
/// A FactorSource is the source of FactorInstance(s).
public struct FactorSource: Sendable, Hashable, Codable, Identifiable {
	/// Kind of factor source
	public let kind: FactorSourceKind

	/// Canonical identifier which uniquely identifies this factor source
	public let id: FactorSourceID

	/// A user facing hint about this FactorSource which is displayed
	/// to the user when she is prompted for this FactorSource during
	/// for example transaction signing. Here are some examples.
	///
	/// * "iPhone 14 Pro Max",
	/// * "Google Pixel 6",
	/// * "Ledger Nano Model X",
	/// * "My friend Lisa"
	/// * "YubiKey 5C NFC"
	/// * "Just a private key put in my standard secure storage."
	/// * "Mnemonic that describes a saga about a crazy horse",
	///
	public private(set) var hint: NonEmptyString

	/// Curve/Derivation scheme
	public let parameters: Parameters

	/// When this factor source for originally added by the user.
	public let addedOn: Date

	/// Date of last usage of this factor source
	///
	/// This is the only mutable property, it is mutable
	/// since we will update it every time this FactorSource
	/// is used.
	public var lastUsedOn: Date

	/// Some factor source requires extra stored properties, e.g.
	/// securityQuestions kind which requires storage of:
	/// * which questions user chose
	/// * the encryptions of the mnemonic
	///
	/// Rather than letting ALL factor source contain ALL possible
	/// extra stored properties as optionals, which will be `nil`
	/// for most FactorSource, we model this with one single optional
	/// being an enym modelling all possible required extra stored
	/// properties.
	public let storage: Storage?

	public init(
		kind: FactorSourceKind,
		id: ID,
		hint: NonEmptyString,
		parameters: Parameters,
		addedOn: Date = .now,
		lastUsedOn: Date = .now,
		storage: Storage? = nil
	) {
		self.kind = kind
		self.id = id
		self.hint = hint
		self.parameters = parameters
		self.addedOn = addedOn
		self.lastUsedOn = lastUsedOn
		self.storage = storage
	}
}

extension FactorSource {
	public var supportsOlympia: Bool {
		parameters.supportsOlympia
	}

	public func changing(hint newHint: NonEmptyString) -> Self {
		var copy = self
		copy.hint = newHint
		return copy
	}
}

#if DEBUG
extension FactorSource {
	public static let previewValueDevice: Self = {
		let mnemonic = try! Mnemonic(phrase: "zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo vote", language: .english)
		return try! Self.device(mnemonic: mnemonic, hint: "preview", olympiaCompatible: false)
	}()
}
#endif
