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
			// The only purpose of this switch is to make sure we get a compilation error when we add a new PersonaData.Entry kind, so
			// we do not forget to handle it here.
			switch PersonaData.Entry.Kind.fullName {
			case .fullName, .dateOfBirth, .companyName, .emailAddress, .phoneNumber, .url, .postalAddress, .creditCard: break
			}

			self.isRequestingName = isRequestingName
			self.numberOfRequestedEmailAddresses = numberOfRequestedEmailAddresses
			self.numberOfRequestedPhoneNumbers = numberOfRequestedPhoneNumbers
		}

		public var kindRequests: [PersonaData.Entry.Kind: KindRequest] {
			var result: [PersonaData.Entry.Kind: KindRequest] = [:]
			if isRequestingName == true {
				result[.fullName] = .entry
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

	public enum MissingEntry: Sendable, Hashable {
		case missingEntry
		case missing(Int)
	}

	public enum KindRequest: Sendable, Hashable {
		case entry
		case number(RequestedNumber)
	}
}

// MARK: - P2P.Dapp.Request.RequestValidation
extension P2P.Dapp.Request {
	public struct RequestValidation: Sendable, Hashable {
		public var missingEntries: [PersonaData.Entry.Kind: MissingEntry] = [:]
		public var existingRequestedEntries: [PersonaData.Entry.Kind: [PersonaData.Entry]] = [:]

		public var response: P2P.Dapp.Request.Response? {
			guard missingEntries.isEmpty else { return nil }
			return try? .init(
				name: existingRequestedEntries.extract(.fullName),
				emailAddresses: existingRequestedEntries.extract(.emailAddress),
				phoneNumbers: existingRequestedEntries.extract(.phoneNumber)
			)
		}
	}
}

private extension [PersonaData.Entry.Kind: [PersonaData.Entry]] {
	func extract<F>(_ kind: PersonaData.Entry.Kind, as: F.Type = F.self) throws -> F? where F: PersonaDataEntryProtocol {
		try self[kind]?.first.map { try $0.extract(as: F.self) }
	}

	func extract<F>(_ kind: PersonaData.Entry.Kind, as: F.Type = F.self) throws -> OrderedSet<F>? where F: PersonaDataEntryProtocol {
		try self[kind].map { try $0.extract() }
	}
}

private extension [PersonaData.Entry] {
	func extract<F>(as _: F.Type = F.self) throws -> OrderedSet<F> where F: PersonaDataEntryProtocol {
		try .init(validating: map { try $0.extract() })
	}
}

extension PersonaData {
	public func responseValidation(for request: P2P.Dapp.Request.PersonaDataRequestItem) -> P2P.Dapp.Request.RequestValidation {
		let kindRequests = request.kindRequests

		var result = P2P.Dapp.Request.RequestValidation()

		for (kind, values) in allExistingEntries {
			guard let kindRequest = kindRequests[kind] else { continue }
			switch validate(values, for: kindRequest) {
			case let .left(missingEntry):
				result.missingEntries[kind] = missingEntry
			case let .right(responseValues):
				result.existingRequestedEntries[kind] = responseValues
			}
		}

		return result
	}

	private func validate(_ entries: [PersonaData.Entry], for request: P2P.Dapp.Request.KindRequest) -> Either<P2P.Dapp.Request.MissingEntry, [Entry]> {
		switch request {
		case .entry:
			guard let first = entries.first else { return .left(.missingEntry) }
			return .right([first])
		case let .number(number):
			let values = Set(entries.prefix(number.quantity))
			let missing = number.quantity - values.count
			guard missing <= 0 else { return .left(.missing(missing)) }
			return .right(Array(values))
		}
	}

	private var allExistingEntries: [PersonaData.Entry.Kind: [PersonaData.Entry]] {
		var result: [PersonaData.Entry.Kind: [PersonaData.Entry]] = [:]
		for entry in entries {
			result[entry.value.discriminator, default: []].append(entry.value)
		}
		return result
	}
}
