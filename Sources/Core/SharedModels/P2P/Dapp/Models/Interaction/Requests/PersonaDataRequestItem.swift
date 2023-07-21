import Prelude
import Profile

// MARK: - P2P.Dapp.Request.PersonaDataRequestItem
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

		public var requestedEntries: [PersonaData.Entry.Kind: RequestType] {
			var result: [PersonaData.Entry.Kind: RequestType] = [:]
			if isRequestingName == true {
				result[.name] = .entry
			}
			if let numberOfRequestedPhoneNumbers, numberOfRequestedPhoneNumbers.isValid {
				result[.phoneNumber] = .number(numberOfRequestedPhoneNumbers)
			}
			if let numberOfRequestedEmailAddresses, numberOfRequestedEmailAddresses.isValid {
				result[.emailAddress] = .number(numberOfRequestedEmailAddresses)
			}
			return result
		}
	}
}

extension P2P.Dapp.Request {
	public typealias Response = P2P.Dapp.Response.WalletInteractionSuccessResponse.PersonaDataRequestResponseItem

	public struct RequestError: Error, Sendable, Hashable {
		public let entries: [PersonaData.Entry.Kind: EntryError]
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

extension P2P.Dapp.Request.RequestType {
	func validate(actualCount: Int) -> P2P.Dapp.Request.EntryError? {
		switch self {
		case .entry:
			return actualCount == 0 ? .missingEntry : nil
		case let .number(number):
			return actualCount < number.quantity ? .missing(number.quantity - actualCount) : nil
		}
	}
}

extension PersonaData {
	public func missingEntries(for request: P2P.Dapp.Request.PersonaDataRequestItem) -> [PersonaData.Entry.Kind: P2P.Dapp.Request.EntryError] {
		let existing = existingEntries(for: request)

		var missing: [PersonaData.Entry.Kind: P2P.Dapp.Request.EntryError] = [:]
		for (kind, request) in request.requestedEntries {
			missing[kind] = request.validate(actualCount: existing[kind] ?? 0)
		}

		return missing
	}

	public func existingEntries(for request: P2P.Dapp.Request.PersonaDataRequestItem) -> [PersonaData.Entry.Kind: Int] {
		var result: [PersonaData.Entry.Kind: Int] = [:]

		result[.name] = name == nil ? 0 : 1
		result[.phoneNumber] = phoneNumbers.count
		result[.emailAddress] = emailAddresses.count

		return result
	}

	public func response(for request: P2P.Dapp.Request.PersonaDataRequestItem) -> Result<P2P.Dapp.Request.Response, P2P.Dapp.Request.RequestError> {
		var missing: [Entry.Kind: P2P.Dapp.Request.EntryError] = [:]
		var response = P2P.Dapp.Request.Response()

		if request.isRequestingName == true {
			if let value = name?.value {
				response.name = value
			} else {
				missing[.name] = .missingEntry
			}
		}

		if let emailsNumber = request.numberOfRequestedEmailAddresses {
			switch emailAddresses.requestedValues(emailsNumber) {
			case let .success(value):
				response.emailAddresses = value
			case let .failure(error):
				missing[.emailAddress] = error
			}
		}

		if let phoneNumbersNumber = request.numberOfRequestedPhoneNumbers {
			switch phoneNumbers.requestedValues(phoneNumbersNumber) {
			case let .success(value):
				response.phoneNumbers = value
			case let .failure(error):
				missing[.emailAddress] = error
			}
		}

		return missing.isEmpty ? .success(response) : .failure(.init(entries: missing))
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
