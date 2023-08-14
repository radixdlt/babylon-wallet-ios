import CasePaths
import EngineKit
import Prelude

// MARK: - DeviceFactorSource
public struct DeviceFactorSource: FactorSourceProtocol {
	public typealias ID = FactorSourceID.FromHash

	public let id: ID
	public var common: FactorSource.Common // We update `lastUsed`

	public var hint: Hint // We update "name"

	internal init(
		id: ID,
		common: FactorSource.Common,
		hint: Hint
	) {
		precondition(id.kind == Self.kind)
		self.id = id
		self.common = common
		self.hint = hint
	}
}

extension DeviceFactorSource {
	/// Kind of factor source
	public static let kind: FactorSourceKind = .device
	public static let casePath: CasePath<FactorSource, Self> = /FactorSource.device
}

// MARK: DeviceFactorSource.Hint
extension DeviceFactorSource {
	public struct Hint: Sendable, Hashable, Codable {
		public typealias Model = Tagged<(Self, model: ()), String>

		/// "iPhone RED"
		public var name: String // mutable so we can update name

		/// "iPhone SE 2nd gen"
		public var model: Model // mutable because name gets `async` fetched and updated later.
	}
}

extension DeviceFactorSource {
	internal static func from(
		mnemonicWithPassphrase: MnemonicWithPassphrase,
		model: Hint.Model = "",
		name: String = "",
		isOlympiaCompatible: Bool,
		addedOn: Date? = nil,
		lastUsedOn: Date? = nil
	) throws -> Self {
		@Dependency(\.date) var date
		return try Self(
			id: .init(kind: .device, mnemonicWithPassphrase: mnemonicWithPassphrase),
			common: .from(
				cryptoParameters: isOlympiaCompatible ? .olympiaBackwardsCompatible : .babylon,
				addedOn: addedOn ?? date(),
				lastUsedOn: lastUsedOn ?? date()
			),
			hint: .init(name: name, model: model)
		)
	}

	public static func babylon(
		mnemonicWithPassphrase: MnemonicWithPassphrase,
		model: Hint.Model = "",
		name: String = "",
		addedOn: Date? = nil,
		lastUsedOn: Date? = nil
	) throws -> Self {
		@Dependency(\.date) var date
		return try Self.from(
			mnemonicWithPassphrase: mnemonicWithPassphrase,
			model: model,
			name: name,
			isOlympiaCompatible: false,
			addedOn: addedOn ?? date(),
			lastUsedOn: lastUsedOn ?? date()
		)
	}

	public static func olympia(
		mnemonicWithPassphrase: MnemonicWithPassphrase,
		model: Hint.Model = "",
		name: String = "",
		addedOn: Date? = nil,
		lastUsedOn: Date? = nil
	) throws -> Self {
		@Dependency(\.date) var date
		return try Self.from(
			mnemonicWithPassphrase: mnemonicWithPassphrase,
			model: model,
			name: name,
			isOlympiaCompatible: true,
			addedOn: addedOn ?? date(),
			lastUsedOn: lastUsedOn ?? date()
		)
	}
}
