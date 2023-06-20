import Foundation

extension PersonaData.Entry {
	private enum CodingKeys: String, CodingKey {
		case discriminator
		case name, dateOfBirth, postalAddress, emailAddress, phoneNumber, creditCard, companyName
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(discriminator, forKey: .discriminator)
		switch self {
		case let .name(value):
			try container.encode(value, forKey: .name)
		case let .dateOfBirth(value):
			try container.encode(value, forKey: .dateOfBirth)
		case let .emailAddress(value):
			try container.encode(value, forKey: .emailAddress)
		case let .postalAddress(value):
			try container.encode(value, forKey: .postalAddress)
		case let .phoneNumber(value):
			try container.encode(value, forKey: .phoneNumber)
		case let .creditCard(value):
			try container.encode(value, forKey: .creditCard)
		case let .companyName(value):
			try container.encode(value, forKey: .companyName)
		}
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let discriminator = try container.decode(PersonaData.Entry.Kind.self, forKey: .discriminator)
		switch discriminator {
		case .name:
			self = try .name(container.decode(PersonaData.Name.self, forKey: .name))
		case .dateOfBirth:
			self = try .dateOfBirth(container.decode(PersonaData.DateOfBirth.self, forKey: .dateOfBirth))
		case .emailAddress:
			self = try .emailAddress(container.decode(PersonaData.EmailAddress.self, forKey: .emailAddress))
		case .postalAddress:
			self = try .postalAddress(container.decode(PersonaData.PostalAddress.self, forKey: .postalAddress))
		case .phoneNumber:
			self = try .phoneNumber(container.decode(PersonaData.PhoneNumber.self, forKey: .phoneNumber))
		case .creditCard:
			self = try .creditCard(container.decode(PersonaData.CreditCard.self, forKey: .creditCard))
		case .companyName:
			self = try .companyName(container.decode(PersonaData.CompanyName.self, forKey: .companyName))
		}
	}
}
