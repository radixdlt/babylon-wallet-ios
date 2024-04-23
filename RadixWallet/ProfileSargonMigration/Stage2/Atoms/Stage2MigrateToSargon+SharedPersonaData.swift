import Foundation
import Sargon

extension SharedPersonaData {
	public mutating func remove(id: PersonaDataEntryID) {
		if id == self.name {
			self.name = nil
		}

		if
			let emailAddresses = self.emailAddresses,
			case var ids = emailAddresses.ids,
			case let request = emailAddresses.request,
			let index = ids.firstIndex(of: id)
		{
			ids.remove(at: index)
			if !request.isFulfilled(by: ids.count) {
				// must delete whole collection since requested quantity is no longer fulfilled.
				self.emailAddresses = nil
			} else {
				self.emailAddresses = .init(request: request, ids: ids)
			}
		}

		// TERRIBLE COPY PASTE - but - this will shortly be moved into Rust Sargon...
		if
			let phoneNumbers = self.phoneNumbers,
			case var ids = phoneNumbers.ids,
			case let request = phoneNumbers.request,
			let index = ids.firstIndex(of: id)
		{
			ids.remove(at: index)
			if !request.isFulfilled(by: ids.count) {
				// must delete whole collection since requested quantity is no longer fulfilled.
				self.phoneNumbers = nil
			} else {
				self.phoneNumbers = .init(request: request, ids: ids)
			}
		}
	}

	mutating func remove(ids: Set<PersonaDataEntryID>) {
		for item in ids {
			remove(id: item)
		}
	}
}

extension SharedPersonaData {
	init(
		requested: P2P.Dapp.Request.PersonaDataRequestItem,
		persona: Persona,
		provided: P2P.Dapp.Response.WalletInteractionSuccessResponse.PersonaDataRequestResponseItem
	) throws {
		try Self(
			name: {
				() -> PersonaDataEntryID? in

				let kind = PersonaData.Entry.Kind.fullName

				// Check if incoming Dapp requested this persona data entry kind
				guard requested.isRequestingName == true else { return nil }

				// Check if PersonaData in Persona contains the entry
				guard let entrySavedInPersona = persona.personaData[keyPath: \.name] else {
					throw MissingRequestedPersonaData(kind: kind)
				}

				// Check if response we are about to send back to dapp contains a value of expected kind
				guard let providedEntry = provided[keyPath: \.name] else {
					throw PersonaDataEntryNotFoundInResponse(kind: kind)
				}

				// Check if response we are about to send back equals to the one saved in Profile
				guard providedEntry == entrySavedInPersona.value else {
					throw SavedPersonaDataInPersonaDoesNotMatchWalletInteractionResponseItem(
						kind: kind
					)
				}

				// Return the id of the entry
				return entrySavedInPersona.id
			}(),
			emailAddresses: { () -> SharedToDappWithPersonaIDsOfPersonaDataEntries? in
				typealias IdentifiedElement = PersonaDataIdentifiedEmailAddress
				typealias Element = IdentifiedElement.Value
				let requestedKeyPath: KeyPath<P2P.Dapp.Request.PersonaDataRequestItem, RequestedQuantity?> = \.numberOfRequestedEmailAddresses
				let personaDataKeyPath: KeyPath<PersonaData, any PersonaDataCollectionProtocol<IdentifiedElement>> = \.emailAddressCollection
				let personaDataEntryKind: PersonaData.Entry.Kind = .emailAddress

				let providedKeyPath: KeyPath<P2P.Dapp.Response.WalletInteractionSuccessResponse.PersonaDataRequestResponseItem, OrderedSet<Element>?> = \.emailAddresses

				// Check if incoming Dapp requests the persona data entry kind
				guard
					let numberOfRequestedElements = requested[keyPath: requestedKeyPath],
					numberOfRequestedElements.quantity > 0
				else {
					// Incoming Dapp request did not ask for access to this kind
					return nil
				}
				// Read out the entries saved in persona (could have been just updated, part of the flow)
				let entriesSavedInPersona = persona.personaData[keyPath: personaDataKeyPath]

				// Ensure the response we plan to send back to Dapp contains the persona data entries as well (else discrepancy in DappInteractionFlow)
				guard let providedEntries: OrderedSet<Element> = provided[keyPath: providedKeyPath] else {
					throw SavedPersonaDataInPersonaDoesNotContainRequestedPersonaData(kind: personaDataEntryKind)
				}

				// Check all entries in response are found in persona
				guard Set(entriesSavedInPersona.values).isSuperset(of: Set(providedEntries.elements)) else {
					throw SavedPersonaDataInPersonaDoesNotMatchWalletInteractionResponseItem(
						kind: personaDataEntryKind
					)
				}

				return SharedToDappWithPersonaIDsOfPersonaDataEntries(
					request: numberOfRequestedElements,
					ids: entriesSavedInPersona.collection.map(
						\.id
					)
				)

			}(),
			phoneNumbers: { () -> SharedToDappWithPersonaIDsOfPersonaDataEntries? in
				nil
			}()
		)
		/*
		 func extractSharedCollection<PersonaDataElement>(
		 	personaDataEntryKind: PersonaData.Entry.Kind,
		 	personaData personaDataKeyPath: KeyPath<PersonaData, PersonaData.CollectionOfIdentifiedEntries<PersonaDataElement>>,
		 	provided providedKeyPath: KeyPath<P2P.Dapp.Response.WalletInteractionSuccessResponse.PersonaDataRequestResponseItem, OrderedSet<PersonaDataElement>?>,
		 	requested requestedKeyPath: KeyPath<P2P.Dapp.Request.PersonaDataRequestItem, RequestedQuantity?>
		 ) throws -> SharedToDappWithPersonaIDsOfPersonaDataEntries?
		 	where
		 	PersonaDataElement: Sendable & Hashable & Codable & BasePersonaDataEntryProtocol
		 {

		 }

		 try self.init(
		 	name: extractField(
		 		personaDataEntryKind: .fullName,
		 		isRequested: \.isRequestingName,
		 		personaData: \.name,
		 		provided: \.name
		 	),
		 	dateOfBirth: nil, // FIXME: When P2P.Dapp.Requests and Response support it
		 	companyName: nil, // FIXME: When P2P.Dapp.Requests and Response support it
		 	emailAddresses: extractSharedCollection(
		 		personaDataEntryKind: .emailAddress,
		 		personaData: \.emailAddresses,
		 		provided: \.emailAddresses,
		 		requested: \.numberOfRequestedEmailAddresses
		 	),
		 	phoneNumbers: extractSharedCollection(
		 		personaDataEntryKind: .phoneNumber,
		 		personaData: \.phoneNumbers,
		 		provided: \.phoneNumbers,
		 		requested: \.numberOfRequestedPhoneNumbers
		 	),
		 	urls: nil, // FIXME: When P2P.Dapp.Requests and Response support it
		 	postalAddresses: nil, // FIXME: When P2P.Dapp.Requests and Response support it
		 	creditCards: nil // FIXME: When P2P.Dapp.Requests and Response support it
		 )
		  */
		sargonProfileFinishMigrateAtEndOfStage1()
	}
}

extension PersonaData {
	var emailAddressCollection: any PersonaDataCollectionProtocol<PersonaDataIdentifiedEmailAddress> {
		self.emailAddresses
	}
}
