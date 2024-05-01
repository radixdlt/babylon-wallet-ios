import Sargon

// MARK: - P2P.Dapp.Request.PersonaDataRequestItem
extension P2P.Dapp.Request {
	public struct PersonaDataRequestItem: Sendable, Hashable, Decodable {
		public let isRequestingName: Bool?
		public let numberOfRequestedEmailAddresses: RequestedQuantity?
		public let numberOfRequestedPhoneNumbers: RequestedQuantity?

		public init(
			isRequestingName: Bool?,
			numberOfRequestedEmailAddresses: RequestedQuantity? = nil,
			numberOfRequestedPhoneNumbers: RequestedQuantity? = nil
		) {
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
		case number(RequestedQuantity)
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
