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

//		public var requestedEntries: Set<PersonaData.Entry.Kind> {
//			var result: Set<PersonaData.Entry.Kind> = []
//			if isRequestingName == true {
//				result.insert(.name)
//			}
//			if numberOfRequestedPhoneNumbers?.isValid == true {
//				result.insert(.phoneNumber)
//			}
//			if numberOfRequestedEmailAddresses?.isValid == true {
//				result.insert(.emailAddress)
//			}
//			return result
//		}
	}

	public struct RequestError: Error, Sendable, Hashable {
		let entries: [PersonaData.Entry.Kind: EntryError]
	}

	public enum EntryError: Error, Sendable, Hashable {
		case missingEntry
		case missing(Int)
	}

	public enum RequestType: Sendable, Hashable {
		case entry
		case number(RequestedNumber)
	}
}

extension PersonaData {
	public func response(for request: P2P.Dapp.Request.PersonaDataRequestItem) -> Result<P2P.Dapp.Response.WalletInteractionSuccessResponse.PersonaDataRequestResponseItem, P2P.Dapp.Request.RequestError> {
		var missing: [Entry.Kind: P2P.Dapp.Request.EntryError] = [:]

		let responseName: PersonaData.Name?
		if request.isRequestingName == true {
			if let value = name?.value {
				responseName = value
			} else {
				responseName = nil
				missing[.name] = .missingEntry
			}
		} else {
			responseName = nil
		}

		let responseEmails: OrderedSet<PersonaData.EmailAddress>?
		if let emailsNumber = request.numberOfRequestedEmailAddresses {
			switch emailAddresses.requestedValues(emailsNumber) {
			case let .success(value):
				responseEmails = value
			case let .failure(error):
				responseEmails = nil
				missing[.emailAddress] = error
			}
		} else {
			responseEmails = nil
		}

		let responsePhoneNumbers: OrderedSet<PersonaData.PhoneNumber>?
		if let phoneNumbersNumber = request.numberOfRequestedPhoneNumbers {
			switch phoneNumbers.requestedValues(phoneNumbersNumber) {
			case let .success(value):
				responsePhoneNumbers = value
			case let .failure(error):
				responsePhoneNumbers = nil
				missing[.emailAddress] = error
			}
		} else {
			responsePhoneNumbers = nil
		}

		guard missing.isEmpty else {
			return .failure(.init(entries: missing))
		}

		return .success(.init(
			name: responseName,
			emailAddresses: responseEmails,
			phoneNumbers: responsePhoneNumbers
		))
	}
}

extension PersonaData.CollectionOfIdentifiedEntries {
	public func requestedValues(_ number: RequestedNumber) -> Result<OrderedSet<Value>, P2P.Dapp.Request.EntryError> {
		let values = Set(collection.elements.map(\.value).prefix(number.quantity))
		let missing = number.quantity - values.count
		guard missing <= 0 else {
			return .failure(.missing(missing))
		}

		return .success(.init(uncheckedUniqueElements: values))
	}

	public var values: OrderedSet<Value>? {
		try? .init(validating: collection.elements.map(\.value))
	}
}
