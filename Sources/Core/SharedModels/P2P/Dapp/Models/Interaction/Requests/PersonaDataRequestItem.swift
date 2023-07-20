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
			self.isRequestingName = isRequestingName
			self.numberOfRequestedEmailAddresses = numberOfRequestedEmailAddresses
			self.numberOfRequestedPhoneNumbers = numberOfRequestedPhoneNumbers
		}

		public var requestedEntries: Set<PersonaData.Entry.Kind> {
			var result: Set<PersonaData.Entry.Kind> = []
			if isRequestingName == true {
				result.insert(.name)
			}
			if numberOfRequestedPhoneNumbers?.isValid == true {
				result.insert(.phoneNumber)
			}
			if numberOfRequestedEmailAddresses?.isValid == true {
				result.insert(.emailAddress)
			}
			return result
		}
	}

	public enum Issue: Sendable, Hashable, Decodable {
		case isMissing
		case needsMore(RequestedNumber)
		case needsFewer(Int) // TODO: Perhaps we should skip this case, and simply pick the requested number of entries?
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

	public func existingRequestEntries(_ item: P2P.Dapp.Request.PersonaDataRequestItem) -> [PersonaData.Entry] {
		let requested = item.requestedEntries
		return entries.filter { requested.contains($0.value.discriminator) }.map(\.value)
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
				return .needsFewer(-missing)
			}
		case .atLeast:
			if missing > 0 {
				return .needsMore(.atLeast(missing))
			}
		}

		return nil
	}
}
