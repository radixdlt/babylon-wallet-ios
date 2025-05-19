import Foundation
import Sargon

extension SharedPersonaData {
	mutating func remove(id: PersonaDataEntryID) {
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

		// TERRIBLE COPY PASTE - but - this will shortly be moved into Rust ..
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
		requested: DappToWalletInteractionPersonaDataRequestItem,
		persona: Persona,
		provided: WalletToDappInteractionPersonaDataRequestResponseItem
	) throws {
		func extractSharedCollection<IdentifiedElement: PersonaDataCollectionElement>(
			requestedKeyPath: KeyPath<DappToWalletInteractionPersonaDataRequestItem, RequestedQuantity?>,
			personaDataKeyPath: KeyPath<PersonaData, [IdentifiedElement]>,
			personaDataEntryKind: PersonaData.Entry.Kind,
			providedKeyPath: KeyPath<WalletToDappInteractionPersonaDataRequestResponseItem, [IdentifiedElement.Value]?>
		) throws -> SharedToDappWithPersonaIDsOfPersonaDataEntries? {
			// Check if incoming Dapp requests the persona data entry kind
			guard
				let numberOfRequestedElements = requested[keyPath: requestedKeyPath],
				numberOfRequestedElements.quantity > 0
			else {
				// Incoming Dapp request did not ask for access to this kind
				return nil
			}
			// Read out the entries saved in persona (could have been just updated, part of the flow)
			let entriesSavedInPersona: [IdentifiedElement] = persona.personaData[keyPath: personaDataKeyPath]

			// Ensure the response we plan to send back to Dapp contains the persona data entries as well (else discrepancy in DappInteractionFlow)
			guard let providedEntries: [IdentifiedElement.Value] = provided[keyPath: providedKeyPath] else {
				throw SavedPersonaDataInPersonaDoesNotContainRequestedPersonaData(kind: personaDataEntryKind)
			}

			// Check all entries in response are found in persona
			let valuesInPersona: Set<IdentifiedElement.Value> = Set(entriesSavedInPersona.map(\.value))
			let providedValues = Set(providedEntries)
			let allEntriesInResponseWasFoundInPersona = valuesInPersona.isSuperset(of: providedValues)
			guard allEntriesInResponseWasFoundInPersona else {
				throw SavedPersonaDataInPersonaDoesNotMatchWalletInteractionResponseItem(
					kind: personaDataEntryKind
				)
			}

			return SharedToDappWithPersonaIDsOfPersonaDataEntries(
				request: numberOfRequestedElements,
				ids: entriesSavedInPersona.map(
					\.id
				)
			)
		}

		try self.init(
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
			emailAddresses: extractSharedCollection(
				requestedKeyPath: \.numberOfRequestedEmailAddresses,
				personaDataKeyPath: \.emailAddressCollection,
				personaDataEntryKind: .emailAddress,
				providedKeyPath: \.emailAddresses
			),
			phoneNumbers: extractSharedCollection(
				requestedKeyPath: \.numberOfRequestedPhoneNumbers,
				personaDataKeyPath: \.phoneNumbersCollection,
				personaDataEntryKind: .phoneNumber,
				providedKeyPath: \.phoneNumbers
			)
		)
	}
}

extension PersonaData {
	var emailAddressCollection: [PersonaDataIdentifiedEmailAddress] {
		emailAddresses.collection
	}

	var phoneNumbersCollection: [PersonaDataIdentifiedPhoneNumber] {
		phoneNumbers.collection
	}
}
