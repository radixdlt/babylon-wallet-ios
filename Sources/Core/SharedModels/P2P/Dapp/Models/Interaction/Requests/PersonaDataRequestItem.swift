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
		var result = P2P.Dapp.Response.WalletInteractionSuccessResponse.PersonaDataRequestResponseItem()

		if request.isRequestingName == true {
			if let value = name?.value {
				result.name = value
			} else {
				missing[.name] = .missingEntry
			}
		}

		if let emailsNumber = request.numberOfRequestedEmailAddresses {
			switch emailAddresses.requestedValues(emailsNumber) {
			case let .success(value):
				result.emailAddresses = value
			case let .failure(error):
				missing[.emailAddress] = error
			}
		}

		if let phoneNumbersNumber = request.numberOfRequestedPhoneNumbers {
			switch phoneNumbers.requestedValues(phoneNumbersNumber) {
			case let .success(value):
				result.phoneNumbers = value
			case let .failure(error):
				missing[.emailAddress] = error
			}
		}

		return missing.isEmpty ? .success(result) : .failure(.init(entries: missing))
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
