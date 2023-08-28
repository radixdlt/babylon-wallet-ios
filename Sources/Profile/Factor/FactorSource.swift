import CasePaths
import Cryptography
import Prelude

// MARK: - FactorSource
public enum FactorSource: BaseFactorSourceProtocol, Sendable, Hashable, Codable, Identifiable {
	public typealias ID = FactorSourceID
	case device(DeviceFactorSource)
	case ledger(LedgerHardwareWalletFactorSource)
	case offDeviceMnemonic(OffDeviceMnemonicFactorSource)
	case securityQuestions(SecurityQuestionsFactorSource)
	case trustedContact(TrustedContactFactorSource)
}

extension FactorSource {
	public var common: FactorSource.Common {
		get { property(\.common) }
		set {
			update(\.common, to: newValue)
		}
	}

	// Compiler crash if we try to use `private func property<Property>(_ keyPath: KeyPath<any FactorSourceProtocol, Property>) -> Property {
	// and use `property(\.id).embed()
	// :/
	public var id: ID {
		switch self {
		case let .device(factorSource): return factorSource.id.embed()
		case let .ledger(factorSource): return factorSource.id.embed()
		case let .offDeviceMnemonic(factorSource): return factorSource.id.embed()
		case let .securityQuestions(factorSource): return factorSource.id.embed()
		case let .trustedContact(factorSource): return factorSource.id.embed()
		}
	}

	public var kind: FactorSourceKind {
		property(\.kind)
	}

	public func embed() -> FactorSource {
		self
	}

	public mutating func update<Property>(
		_ writableKeyPath: WritableKeyPath<any FactorSourceProtocol, Property>,
		to newValue: Property
	) {
		switch self {
		case var .device(factorSource as (any FactorSourceProtocol)):
			factorSource[keyPath: writableKeyPath] = newValue
			self = factorSource.embed()

		case var .ledger(factorSource as (any FactorSourceProtocol)):
			factorSource[keyPath: writableKeyPath] = newValue
			self = factorSource.embed()

		case var .offDeviceMnemonic(factorSource as (any FactorSourceProtocol)):
			factorSource[keyPath: writableKeyPath] = newValue
			self = factorSource.embed()

		case var .securityQuestions(factorSource as (any FactorSourceProtocol)):
			factorSource[keyPath: writableKeyPath] = newValue
			self = factorSource.embed()

		case var .trustedContact(factorSource as (any FactorSourceProtocol)):
			factorSource[keyPath: writableKeyPath] = newValue
			self = factorSource.embed()
		}
	}

	private func property<Property>(_ keyPath: KeyPath<any BaseFactorSourceProtocol, Property>) -> Property {
		switch self {
		case let .device(factorSource): return factorSource[keyPath: keyPath]
		case let .ledger(factorSource): return factorSource[keyPath: keyPath]
		case let .offDeviceMnemonic(factorSource): return factorSource[keyPath: keyPath]
		case let .securityQuestions(factorSource): return factorSource[keyPath: keyPath]
		case let .trustedContact(factorSource): return factorSource[keyPath: keyPath]
		}
	}
}

extension FactorSource {
	private enum CodingKeys: String, CodingKey {
		case discriminator, device, ledgerHQHardwareWallet, offDeviceMnemonic, securityQuestions, trustedContact
	}

	public func encode(to encoder: Encoder) throws {
		var keyedContainer = encoder.container(keyedBy: CodingKeys.self)
		try keyedContainer.encode(kind, forKey: .discriminator)
		switch self {
		case let .device(device):
			try keyedContainer.encode(device, forKey: .device)
		case let .ledger(ledger):
			try keyedContainer.encode(ledger, forKey: .ledgerHQHardwareWallet)
		case let .offDeviceMnemonic(ledger):
			try keyedContainer.encode(ledger, forKey: .offDeviceMnemonic)
		case let .trustedContact(ledger):
			try keyedContainer.encode(ledger, forKey: .trustedContact)
		case let .securityQuestions(ledger):
			try keyedContainer.encode(ledger, forKey: .securityQuestions)
		}
	}

	public init(from decoder: Decoder) throws {
		let keyedContainer = try decoder.container(keyedBy: CodingKeys.self)
		let discriminator = try keyedContainer.decode(FactorSourceKind.self, forKey: .discriminator)

		switch discriminator {
		case .device:
			self = try .device(
				keyedContainer.decode(DeviceFactorSource.self, forKey: .device)
			)

		case .ledgerHQHardwareWallet:
			self = try .ledger(
				keyedContainer.decode(LedgerHardwareWalletFactorSource.self, forKey: .ledgerHQHardwareWallet)
			)

		case .offDeviceMnemonic:
			self = try .offDeviceMnemonic(
				keyedContainer.decode(OffDeviceMnemonicFactorSource.self, forKey: .offDeviceMnemonic)
			)

		case .securityQuestions:
			self = try .securityQuestions(
				keyedContainer.decode(SecurityQuestionsFactorSource.self, forKey: .securityQuestions)
			)

		case .trustedContact:
			self = try .trustedContact(
				keyedContainer.decode(TrustedContactFactorSource.self, forKey: .trustedContact)
			)
		}
	}
}

extension FactorSource {
	public func extract<F>(_ type: F.Type = F.self) -> F? where F: FactorSourceProtocol {
		F.extract(from: self)
	}

	public func extract<F>(as _: F.Type = F.self) throws -> F where F: FactorSourceProtocol {
		guard let extracted = extract(F.self) else {
			throw IncorrectFactorSourceType(expectedKind: F.kind, actualKind: kind)
		}
		return extracted
	}
}

// MARK: - IncorrectFactorSourceType
public struct IncorrectFactorSourceType: Swift.Error {
	public let expectedKind: FactorSourceKind
	public let actualKind: FactorSourceKind
}

#if DEBUG
extension FactorSource {
	public static func device(_ name: String, olympiaCompat: Bool) -> Self {
		withDependencies {
			$0.date = .constant(.init(timeIntervalSince1970: 0))
		} operation: {
			let device = try! DeviceFactorSource(
				id: .device(hash: Data.random(byteCount: 32)),
				common: .init(
					cryptoParameters: olympiaCompat ? .olympiaBackwardsCompatible : .babylon
				),
				hint: .init(name: name, model: "", mnemonicWordCount: .twentyFour)
			)
			return device.embed()
		}
	}

	public static func ledger(_ name: String, olympiaCompat: Bool) -> Self {
		withDependencies {
			$0.date = .constant(.init(timeIntervalSince1970: 0))
		} operation: {
			let ledger = try! LedgerHardwareWalletFactorSource(
				id: .init(kind: .ledgerHQHardwareWallet, hash: Data.random(byteCount: 32)),
				common: .init(
					cryptoParameters: olympiaCompat ? .olympiaBackwardsCompatible : .babylon
				),
				hint: .init(name: .init(name), model: .nanoS)
			)
			return ledger.embed()
		}
	}

	public static let deviceOne = Self.device("One", olympiaCompat: true)
	public static let deviceTwo = Self.device("Two", olympiaCompat: false)
	public static let ledgerOne = Self.ledger("One", olympiaCompat: false)
	public static let ledgerTwo = Self.ledger("Two", olympiaCompat: true)
}
#endif
