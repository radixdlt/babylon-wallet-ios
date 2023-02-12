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

extension EntitySecurityState {
	public var _description: String {
		switch self {
		case let .unsecured(unsecuredEntityControl):
			return "EntitySecurityState.unsecured(\(unsecuredEntityControl)"
		}
	}

	public var description: String {
		_description
	}

	public var customDumpDescription: String {
		_description
	}
}

extension EntitySecurityState {
	internal enum Discriminator: String, Sendable, Equatable, Codable {
		case unsecured
	}

	public enum CodingKeys: String, CodingKey {
		case discriminator, unsecuredEntityControl
	}

	internal var discriminator: Discriminator {
		switch self {
		case .unsecured: return .unsecured
		}
	}

	public func encode(to encoder: Encoder) throws {
		var keyedContainer = encoder.container(keyedBy: CodingKeys.self)
		try keyedContainer.encode(discriminator, forKey: .discriminator)
		switch self {
		case let .unsecured(unsecuredEntityControl):
			try keyedContainer.encode(unsecuredEntityControl, forKey: .unsecuredEntityControl)
		}
	}

	public init(from decoder: Decoder) throws {
		let keyedContainer = try decoder.container(keyedBy: CodingKeys.self)
		let discriminator = try keyedContainer.decode(Discriminator.self, forKey: .discriminator)
		switch discriminator {
		case .unsecured:
			self = try .unsecured(keyedContainer.decode(UnsecuredEntityControl.self, forKey: .unsecuredEntityControl))
		}
	}
}

extension Identifiable where Self: FactorInstanceProtocol, ID == FactorSourceReference {
	public var id: ID { factorSourceReference }
}
