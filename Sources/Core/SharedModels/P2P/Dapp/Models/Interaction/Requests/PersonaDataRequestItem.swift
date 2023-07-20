import Prelude
import Profile

extension P2P.Dapp.Request {
	public struct PersonaDataRequestItem: Sendable, Hashable, Decodable {
		public let isRequestingName: Bool?
		public let numberOfRequestedEmailAddresses: RequestedNumber?
		public let numberOfRequestedPhoneNumbers: RequestedNumber?

		public init(
			isRequestingName: Bool?,
			numberOfRequestedEmailAddresses: RequestedNumber? = nil,
			numberOfRequestedPhoneNumbers: RequestedNumber? = nil
		) {
			// The only purpose of this switch is to make sure we get a compilation error when we add a new PersonaData.Entry kind, so
			// we do not forget to handle it here.
			switch PersonaData.Entry.Kind.name {
			case .name, .dateOfBirth, .companyName, .emailAddress, .phoneNumber, .url, .postalAddress, .creditCard: break
			}

			self.isRequestingName = isRequestingName
			self.numberOfRequestedEmailAddresses = numberOfRequestedEmailAddresses
			self.numberOfRequestedPhoneNumbers = numberOfRequestedPhoneNumbers
		}
	}

	public enum Issue: Sendable, Hashable, Decodable {
		case isMissing
		case needsMore(RequestedNumber)
		case needsFewer(RequestedNumber)
	}
}

extension PersonaData {
	public func requestIssues(_ item: P2P.Dapp.Request.PersonaDataRequestItem) -> [Entry.Kind: P2P.Dapp.Request.Issue] {
		var result: [Entry.Kind: P2P.Dapp.Request.Issue] = [:]
		if item.isRequestingName == true, name == nil {
			result[.name] = .isMissing
		}
		if let emailsNumber = item.numberOfRequestedEmailAddresses {
			result[.emailAddress] = emailAddresses.requestIssue(emailsNumber)
		}

		if let phoneNumbersNumber = item.numberOfRequestedPhoneNumbers {
			result[.phoneNumber] = emailAddresses.requestIssue(phoneNumbersNumber)
		}

		return result
	}
}

extension PersonaData.CollectionOfIdentifiedEntries {
	public func requestIssue(_ number: RequestedNumber) -> P2P.Dapp.Request.Issue? {
		let missing = number.quantity - count

		switch number.quantifier {
		case .exactly:
			if missing > 0 {
				return .needsMore(.exactly(missing))
			} else if missing < 0 {
				return .needsFewer(.exactly(-missing))
			}
		case .atLeast:
			if missing > 0 {
				return .needsMore(.atLeast(missing))
			}
		}

		return nil
	}
}
