import Foundation

extension PersonaData.Entry {
	private enum CodingKeys: String, CodingKey {
		case discriminator
		case name, dateOfBirth, companyName, emailAddress, phoneNumber, url, postalAddress, creditCard
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(discriminator, forKey: .discriminator)
		switch self {
		case let .name(value):
			try container.encode(value, forKey: .name)
		case let .dateOfBirth(value):
			try container.encode(value, forKey: .dateOfBirth)
		case let .companyName(value):
			try container.encode(value, forKey: .companyName)
		case let .emailAddress(value):
			try container.encode(value, forKey: .emailAddress)
		case let .phoneNumber(value):
			try container.encode(value, forKey: .phoneNumber)
		case let .url(value):
			try container.encode(value, forKey: .url)
		case let .postalAddress(value):
			try container.encode(value, forKey: .postalAddress)
		case let .creditCard(value):
			try container.encode(value, forKey: .creditCard)
		}
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let discriminator = try container.decode(PersonaData.Entry.Kind.self, forKey: .discriminator)
		switch discriminator {
		case .fullName:
			self = try .name(container.decode(PersonaData.Name.self, forKey: .name))
		case .dateOfBirth:
			self = try .dateOfBirth(container.decode(PersonaData.DateOfBirth.self, forKey: .dateOfBirth))
		case .companyName:
			self = try .companyName(container.decode(PersonaData.CompanyName.self, forKey: .companyName))
		case .emailAddress:
			self = try .emailAddress(container.decode(PersonaData.EmailAddress.self, forKey: .emailAddress))
		case .phoneNumber:
			self = try .phoneNumber(container.decode(PersonaData.PhoneNumber.self, forKey: .phoneNumber))
		case .url:
			self = try .url(container.decode(PersonaData.AssociatedURL.self, forKey: .url))
		case .postalAddress:
			self = try .postalAddress(container.decode(PersonaData.PostalAddress.self, forKey: .postalAddress))
		case .creditCard:
			self = try .creditCard(container.decode(PersonaData.CreditCard.self, forKey: .creditCard))
		}
	}
}
