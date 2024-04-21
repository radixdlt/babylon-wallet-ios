import Sargon
import SargonUniFFI

extension PersonaData.Entry {
	private enum CodingKeys: String, CodingKey {
		case discriminator

		case name
		case emailAddress
		case phoneNumber
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(discriminator, forKey: .discriminator)
		switch self {
		case let .name(value):
			try container.encode(value, forKey: .name)
		case let .emailAddress(value):
			try container.encode(value, forKey: .emailAddress)
		case let .phoneNumber(value):
			try container.encode(value, forKey: .phoneNumber)
		}
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let discriminator = try container.decode(PersonaData.Entry.Kind.self, forKey: .discriminator)
		switch discriminator {
		case .fullName:
			self = try .name(container.decode(PersonaData.Name.self, forKey: .name))
		case .emailAddress:
			self = try .emailAddress(container.decode(PersonaData.EmailAddress.self, forKey: .emailAddress))
		case .phoneNumber:
			self = try .phoneNumber(container.decode(PersonaData.PhoneNumber.self, forKey: .phoneNumber))
		}
	}
}

extension PersonaData {
	public typealias Name = PersonaDataEntryName
	public typealias EmailAddress = PersonaDataEntryEmailAddress
	public typealias PhoneNumber = PersonaDataEntryPhoneNumber
}
