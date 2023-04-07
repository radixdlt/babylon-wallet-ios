import Cryptography
import Prelude

// MARK: - _FactorSourceProtocol
protocol _FactorSourceProtocol {
	var kind: FactorSourceKind { get }
	var id: FactorSourceID { get }
	var hint: NonEmptyString { get }
	var parameters: FactorSource.Parameters { get }
	var addedOn: Date { get }
	var lastUsedOn: Date { get }
	var storage: FactorSource.Storage? { get }
}

// MARK: - FactorSource
/// A FactorSource is the source of FactorInstance(s).
public struct FactorSource:
	_FactorSourceProtocol,
	Sendable,
	Hashable,
	Codable,
	Identifiable,
	CustomStringConvertible,
	CustomDumpReflectable
{
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
	/// The reason why this is mutable (`var`) instead of immutable `let` is
	/// an implementation detailed on iOS, where reading the device name
	/// and model is `async` but we want to be able to `sync` create the
	/// profile, thus tis property at a later point in time where an async
	/// context is available.
	public var hint: NonEmptyString

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
	public var storage: Storage?

	init(
		kind: FactorSourceKind,
		id: ID,
		hint: NonEmptyString,
		parameters: Parameters,
		storage: Storage?,
		addedOn: Date,
		lastUsedOn: Date
	) {
		self.id = id
		self.kind = kind
		self.hint = hint
		self.parameters = parameters
		self.storage = storage
		self.addedOn = addedOn
		self.lastUsedOn = lastUsedOn
	}

	public init(
		kind: FactorSourceKind,
		id: ID,
		hint: NonEmptyString,
		parameters: Parameters,
		storage: Storage? = nil
	) {
		@Dependency(\.date) var date

		self.init(
			kind: kind,
			id: id,
			hint: hint,
			parameters: parameters,
			storage: storage,
			addedOn: date(),
			lastUsedOn: date()
		)
	}
}

extension FactorSource {
	public var supportsOlympia: Bool {
		parameters.supportsOlympia
	}
}

extension FactorSource {
	public var customDumpMirror: Mirror {
		.init(
			self,
			children: [
				"id": String(describing: id),
				"kind": kind,
				"hint": hint,
				"parameters": parameters,
				"addedOn": addedOn,
				"lastUsedOn": lastUsedOn,
				"storage": String(describing: storage),
			],
			displayStyle: .struct
		)
	}

	public var description: String {
		"""
		"id": \(String(describing: id)),
		"kind": \(kind),
		"hint": \(hint),
		"parameters": \(parameters),
		"addedOn": \(addedOn.ISO8601Format()),
		"lastUsedOn": \(lastUsedOn.ISO8601Format()),
		"storage": \(String(describing: storage))
		"""
	}
}

#if DEBUG
extension FactorSource {
	public static let previewValueDevice: Self = {
		let mnemonic = try! Mnemonic(phrase: "zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo vote", language: .english)
		return try! Self(
			kind: .device,
			id: id(fromRoot: mnemonic.hdRoot(passphrase: "")),
			hint: "previewValue",
			parameters: .default,
			storage: .forDevice(.init()),
			addedOn: .init(timeIntervalSince1970: 0),
			lastUsedOn: .init(timeIntervalSince1970: 0)
		)
	}()
}

#endif
