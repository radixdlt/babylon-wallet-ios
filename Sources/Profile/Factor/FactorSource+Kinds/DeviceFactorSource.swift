import CasePaths
import Prelude

// MARK: - DeviceFactorSource
public struct DeviceFactorSource: FactorSourceProtocol {
	/// Kind of factor source
	public static let kind: FactorSourceKind = .device
	public static let casePath: CasePath<FactorSource, Self> = /FactorSource.device

	public struct Hint: Sendable, Hashable, Codable {
		/// "iPhone RED"
		// The reason why this is mutable (`var`) instead of immutable `let` is
		// an implementation detailed on iOS, where reading the device name
		// and model is `async` but we want to be able to `sync` create the
		// profile, thus this property at a later point in time where an async
		// context is available.
		//
		public var name: Name; public typealias Name = Tagged<(Self, name: ()), String>

		/// "iPhone SE 2nd gen"
		// The reason why this is mutable (`var`) instead of immutable `let` is
		// an implementation detailed on iOS, where reading the device name
		// and model is `async` but we want to be able to `sync` create the
		// profile, thus this property at a later point in time where an async
		// context is available.
		//
		public var model: Model; public typealias Model = Tagged<(Self, model: ()), String>
	}

	// Mutable so we can update "lastUsedOn"
	public var common: FactorSource.Common

	// Mutable so we can update "name"
	public var hint: Hint

	/// nil for olympia
	public var nextDerivationIndicesPerNetwork: NextDerivationIndicesPerNetwork?

	public init(
		common: FactorSource.Common,
		hint: Hint,
		nextDerivationIndicesPerNetwork: NextDerivationIndicesPerNetwork? = nil
	) {
		self.common = common
		self.hint = hint
		self.nextDerivationIndicesPerNetwork = nextDerivationIndicesPerNetwork
	}
}

extension DeviceFactorSource {
	public static func from(
		mnemonicWithPassphrase: MnemonicWithPassphrase,
		model: Hint.Model = "",
		name: Hint.Name = "",
		isOlympiaCompatible: Bool,
		addedOn: Date,
		lastUsedOn: Date
	) throws -> Self {
		try Self(
			common: .from(
				factorSourceKind: .device,
				mnemonicWithPassphrase: mnemonicWithPassphrase,
				cryptoParameters: isOlympiaCompatible ? .olympiaBackwardsCompatible : .babylon,
				addedOn: addedOn,
				lastUsedOn: lastUsedOn
			),
			hint: .init(name: name, model: model),
			nextDerivationIndicesPerNetwork: isOlympiaCompatible ? nil : .init()
		)
	}

	public static func babylon(
		mnemonicWithPassphrase: MnemonicWithPassphrase,
		model: Hint.Model = "",
		name: Hint.Name = "",
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
		name: Hint.Name = "",
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

import EngineToolkitModels
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
