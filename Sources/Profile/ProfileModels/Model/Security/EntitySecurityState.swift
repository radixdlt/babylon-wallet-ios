import Prelude

// MARK: - EntitySecurityState
/// Security state of an entity (Account/Persona).
public enum EntitySecurityState:
	Sendable,
	Hashable,
	Codable,
	CustomStringConvertible,
	CustomDumpStringConvertible
{
	/// A non-"securitfied" entity (Account/Persona). Protected
	/// with single factor instance until securified, and
	/// thus protected with an "AccessControl".
	case unsecured(UnsecuredEntityControl)
}

public extension EntitySecurityState {
	var _description: String {
		switch self {
		case let .unsecured(unsecuredEntityControl):
			return "EntitySecurityState.unsecured(\(unsecuredEntityControl)"
		}
	}

	var description: String {
		_description
	}

	var customDumpDescription: String {
		_description
	}
}

public extension EntitySecurityState {
	internal enum Discriminator: String, Sendable, Equatable, Codable {
		case unsecured
	}

	enum CodingKeys: String, CodingKey {
		case discriminator, unsecuredEntityControl
	}

	internal var discriminator: Discriminator {
		switch self {
		case .unsecured: return .unsecured
		}
	}

	func encode(to encoder: Encoder) throws {
		var keyedContainer = encoder.container(keyedBy: CodingKeys.self)
		try keyedContainer.encode(discriminator, forKey: .discriminator)
		switch self {
		case let .unsecured(unsecuredEntityControl):
			try keyedContainer.encode(unsecuredEntityControl, forKey: .unsecuredEntityControl)
		}
	}

	init(from decoder: Decoder) throws {
		let keyedContainer = try decoder.container(keyedBy: CodingKeys.self)
		let discriminator = try keyedContainer.decode(Discriminator.self, forKey: .discriminator)
		switch discriminator {
		case .unsecured:
			self = try .unsecured(keyedContainer.decode(UnsecuredEntityControl.self, forKey: .unsecuredEntityControl))
		}
	}
}

public extension Identifiable where Self: FactorInstanceProtocol, ID == FactorSourceReference {
	var id: ID { factorSourceReference }
}
