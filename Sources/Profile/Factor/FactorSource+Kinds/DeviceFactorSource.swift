import CasePaths
import Prelude

// MARK: - DeviceFactorSource
public struct DeviceFactorSource: FactorSourceProtocol {
	public var common: FactorSource.Common // We update `lastUsed`

	public var hint: Hint // We update "name"

	public var nextDerivationIndicesPerNetwork: NextDerivationIndicesPerNetwork? // nil for olympia

	internal init(
		common: FactorSource.Common,
		hint: Hint,
		nextDerivationIndicesPerNetwork: NextDerivationIndicesPerNetwork? = nil
	) {
		precondition(common.id.factorSourceKind == Self.kind)
		self.common = common
		self.hint = hint
		self.nextDerivationIndicesPerNetwork = nextDerivationIndicesPerNetwork
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
			common: .from(
				factorSourceKind: Self.kind,
				mnemonicWithPassphrase: mnemonicWithPassphrase,
				cryptoParameters: isOlympiaCompatible ? .olympiaBackwardsCompatible : .babylon,
				addedOn: addedOn ?? date(),
				lastUsedOn: lastUsedOn ?? date()
			),
			hint: .init(name: name, model: model),
			nextDerivationIndicesPerNetwork: isOlympiaCompatible ? nil : .init()
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

import EngineToolkit
extension DeviceFactorSource {
	public func nextDerivationIndex(for entityKind: EntityKind, networkID: NetworkID) throws -> Profile.Network.NextDerivationIndices.Index {
		guard let nextDerivationIndicesPerNetwork else {
			throw CalledDerivationPathOnOlympiaDeviceFactorNotSupported()
		}
		return nextDerivationIndicesPerNetwork.nextForEntity(kind: entityKind, networkID: networkID)
	}

	public func derivationPath(forNext entityKind: EntityKind, networkID: NetworkID) throws -> DerivationPath {
		guard let nextDerivationIndicesPerNetwork else {
			throw CalledDerivationPathOnOlympiaDeviceFactorNotSupported()
		}
		return try nextDerivationIndicesPerNetwork.derivationPathForNextEntity(
			kind: entityKind,
			networkID: networkID
		)
	}
}

// MARK: - CalledDerivationPathOnOlympiaDeviceFactorNotSupported
struct CalledDerivationPathOnOlympiaDeviceFactorNotSupported: Swift.Error {}
