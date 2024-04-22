import Foundation
import Sargon

extension SharedPersonaData {
	public mutating func remove(id: PersonaDataEntryID) {
		sargonProfileFinishMigrateAtEndOfStage1()
		/*
		 func removeCollectionIfNeeded(
		 	at keyPath: WritableKeyPath<Self, SharedPersonaData.SharedCollection?>
		 ) {
		 	guard
		 		var collection = self[keyPath: keyPath],
		 		collection.ids.contains(id)
		 	else { return }
		 	collection.ids.remove(id)
		 	switch collection.request.quantifier {
		 	case .atLeast:
		 		if collection.ids.count < collection.request.quantity {
		 			// must delete whole collection since requested quantity is no longer fulfilled.
		 			self[keyPath: keyPath] = nil
		 		}
		 	case .exactly:
		 		// Must delete whole collection since requested quantity is no longer fulfilled,
		 		// since we **just** deleted the id from `ids`.
		 		self[keyPath: keyPath] = nil
		 	}
		 }

		 func removeEntryIfNeeded(
		 	at keyPath: WritableKeyPath<Self, PersonaDataEntryID?>
		 ) {
		 	guard self[keyPath: keyPath] == id else { return }
		 	self[keyPath: keyPath] = nil
		 }

		 removeEntryIfNeeded(at: \.name)
		 removeEntryIfNeeded(at: \.dateOfBirth)
		 removeEntryIfNeeded(at: \.companyName)
		 removeCollectionIfNeeded(at: \.emailAddresses)
		 removeCollectionIfNeeded(at: \.phoneNumbers)
		 removeCollectionIfNeeded(at: \.urls)
		 removeCollectionIfNeeded(at: \.postalAddresses)
		 removeCollectionIfNeeded(at: \.creditCards)

		 // The only purpose of this switch is to make sure we get a compilation error when we add a new PersonaData.Entry kind, so
		 // we do not forget to handle it here.
		 switch PersonaData.Entry.Kind.fullName {
		 case .fullName, .dateOfBirth, .companyName, .emailAddress, .phoneNumber, .url, .postalAddress, .creditCard: break
		 }
		 */
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
		/*
		 func extractField<PersonaDataEntry>(
		 	personaDataEntryKind: PersonaData.Entry.Kind,
		 	isRequested isRequestedKeyPath: KeyPath<P2P.Dapp.Request.PersonaDataRequestItem, Bool?>,
		 	personaData personaDataKeyPath: KeyPath<PersonaData, PersonaData.IdentifiedEntry<PersonaDataEntry>?>,
		 	provided providedKeyPath: KeyPath<P2P.Dapp.Response.WalletInteractionSuccessResponse.PersonaDataRequestResponseItem, PersonaDataEntry?>
		 ) throws -> PersonaDataEntryID? where PersonaDataEntry: Hashable & PersonaDataEntryProtocol {
		 	// Check if incoming Dapp requested this persona data entry kind
		 	guard requested[keyPath: isRequestedKeyPath] == true else { return nil }

		 	// Check if PersonaData in Persona contains the entry
		 	guard let entrySavedInPersona = persona.personaData[keyPath: personaDataKeyPath] else {
		 		loggerGlobal.error("PersonaData in Persona does not contain expected requested persona data entry of kind: \(personaDataEntryKind)")
		 		throw MissingRequestedPersonaData(kind: personaDataEntryKind)
		 	}

		 	// Check if response we are about to send back to dapp contains a value of expected kind
		 	guard let providedEntry = provided[keyPath: providedKeyPath] else {
		 		loggerGlobal.error("Discrepancy, the response we are about to send back to dapp does not contain the requested persona data entry of kind: \(personaDataEntryKind)")
		 		throw PersonaDataEntryNotFoundInResponse(kind: personaDataEntryKind)
		 	}

		 	// Check if response we are about to send back equals to the one saved in Profile
		 	guard providedEntry == entrySavedInPersona.value else {
		 		loggerGlobal.error("Discrepancy, the value of the persona data entry does not match what is saved in profile: [response to dapp]: '\(providedEntry)' != '\(entrySavedInPersona.value)' [saved in Profile]")
		 		throw SavedPersonaDataInPersonaDoesNotMatchWalletInteractionResponseItem(
		 			kind: personaDataEntryKind
		 		)
		 	}

		 	// Return the id of the entry
		 	return entrySavedInPersona.id
		 }

		 func extractSharedCollection<PersonaDataElement>(
		 	personaDataEntryKind: PersonaData.Entry.Kind,
		 	personaData personaDataKeyPath: KeyPath<PersonaData, PersonaData.CollectionOfIdentifiedEntries<PersonaDataElement>>,
		 	provided providedKeyPath: KeyPath<P2P.Dapp.Response.WalletInteractionSuccessResponse.PersonaDataRequestResponseItem, OrderedSet<PersonaDataElement>?>,
		 	requested requestedKeyPath: KeyPath<P2P.Dapp.Request.PersonaDataRequestItem, RequestedQuantity?>
		 ) throws -> SharedCollection?
		 	where
		 	PersonaDataElement: Sendable & Hashable & Codable & BasePersonaDataEntryProtocol
		 {
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
		 	guard let providedEntries = provided[keyPath: providedKeyPath] else {
		 		loggerGlobal.error("Discrepancy in DappInteractionFlow, Dapp requests access to persona data entry of kind: \(personaDataEntryKind), specifically: \(numberOfRequestedElements) many, which where in fact found in PersonaData saved in Persona, however, the response we are aboutto send back to Dapp does not contain it.")
		 		throw SavedPersonaDataInPersonaDoesNotContainRequestedPersonaData(kind: personaDataEntryKind)
		 	}

		 	// Check all entries in response are found in persona
		 	guard Set(entriesSavedInPersona.map(\.value)).isSuperset(of: Set(providedEntries)) else {
		 		loggerGlobal.error("Discrepancy in DappInteractionFlow, response back to dapp contains entries which are not in PersonaData in Persona.")
		 		throw SavedPersonaDataInPersonaDoesNotMatchWalletInteractionResponseItem(
		 			kind: personaDataEntryKind
		 		)
		 	}

		 	return try SharedPersonaData.SharedCollection(
		 		ids: OrderedSet(validating: entriesSavedInPersona.map(\.id)),
		 		forRequest: numberOfRequestedElements
		 	)
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
