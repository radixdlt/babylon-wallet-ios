import Cryptography
import Prelude

// MARK: - _FactorSourceProtocol
protocol _FactorSourceProtocol {
	var kind: FactorSourceKind { get }
	var id: FactorSourceID { get }
	var label: FactorSource.Label { get }
	var description: FactorSource.Description { get }
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
	CustomDebugStringConvertible,
	CustomDumpReflectable
{
	/// Kind of factor source
	public let kind: FactorSourceKind

	/// Canonical identifier which uniquely identifies this factor source
	public let id: FactorSourceID

	/// A user facing **label** about this FactorSource which is displayed
	/// to the user when she is prompted for this FactorSource during
	/// for example transaction signing. For most FactorSource kinds
	/// this value will be a *name*, here are some examples:
	///
	/// * `.device`: "iPhone RED"
	/// * `.ledgerHQHardwareWallet`: "Ledger MOON Edition"
	/// * `.trustedEntity`: "Sarah"
	/// * `.offDeviceMnemonic`: "Story about a horse and a battery"
	/// * `.securityQuestion`: ""
	///
	/// The reason why this is mutable (`var`) instead of immutable `let` is
	/// an implementation detailed on iOS, where reading the device name
	/// and model is `async` but we want to be able to `sync` create the
	/// profile, thus this property at a later point in time where an async
	/// context is available.
	///
	public var label: Label; public typealias Label = Tagged<(Self, label: ()), String>

	/// A user facing **description** about this FactorSource which is displayed
	/// to the user when she is prompted for this FactorSource during
	/// for example transaction signing. For most FactorSource kinds
	/// this value will be a *model*, here are some examples:
	///
	/// * `.device`: "iPhone SE 2nd gen"
	/// * `.ledgerHQHardwareWallet`: "nanoS+"
	/// * `.trustedEntity`: "Friend"
	/// * `.offDeviceMnemonic`: "Stored in the place where I played often with my friend A***"
	/// * `.securityQuestion`: ""
	///
	/// The reason why this is mutable (`var`) instead of immutable `let` is
	/// an implementation detailed on iOS, where reading the device name
	/// and model is `async` but we want to be able to `sync` create the
	/// profile, thus this property at a later point in time where an async
	/// context is available.
	///
	public var description: Description; public typealias Description = Tagged<(Self, description: ()), String>

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
		label: Label,
		description: Description,
		parameters: Parameters,
		storage: Storage?,
		addedOn: Date,
		lastUsedOn: Date
	) {
		self.id = id
		self.kind = kind
		self.label = label
		self.description = description
		self.parameters = parameters
		self.storage = storage
		self.addedOn = addedOn
		self.lastUsedOn = lastUsedOn
	}

	public init(
		kind: FactorSourceKind,
		id: ID,
		label: Label,
		description: Description,
		parameters: Parameters,
		storage: Storage? = nil
	) {
		@Dependency(\.date) var date

		self.init(
			kind: kind,
			id: id,
			label: label,
			description: description,
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
				"label": label,
				"description": description,
				"parameters": parameters,
				"addedOn": addedOn,
				"lastUsedOn": lastUsedOn,
				"storage": String(describing: storage),
			],
			displayStyle: .struct
		)
	}

	public var debugDescription: String {
		"""
		"id": \(String(describing: id)),
		"kind": \(kind),
		"label": \(label),
		"description": \(description),
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
			label: "previewValue",
			description: "preview description",
			parameters: .default,
			storage: .entityCreating(.init()),
			addedOn: .init(timeIntervalSince1970: 0),
			lastUsedOn: .init(timeIntervalSince1970: 0)
		)
	}()
}

#endif
