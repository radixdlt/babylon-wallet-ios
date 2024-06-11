import Foundation
import OrderedCollections
import Sargon

extension WalletToDappInteractionPersonaDataRequestResponseItem {
	init(
		personaDataRequested requested: DappToWalletInteractionPersonaDataRequestItem,
		personaData: PersonaData
	) throws {
		try self.init(
			name: { () -> PersonaDataEntryName? in
				// Check if incoming Dapp requested this persona data entry kind
				guard requested[keyPath: \.isRequestingName] == true else { return nil }
				guard let personaDataEntry = personaData[keyPath: \.name] else { return nil }
				return personaDataEntry.value
			}(),
			emailAddresses: { () -> [PersonaDataEntryEmailAddress]? in
				// Check if incoming Dapp requests the persona data entry kind
				guard
					let numberOfRequestedElements = requested[keyPath: \.numberOfRequestedEmailAddresses],
					numberOfRequestedElements.quantity > 0
				else {
					// Incoming Dapp request did not ask for access to this kind
					return nil
				}
				let personaDataEntries = personaData[keyPath: \.emailAddresses]
				let personaDataEntriesOrderedSet = try OrderedSet<PersonaDataEntryEmailAddress>(validating: personaDataEntries.collection.map(\.value))

				guard personaDataEntriesOrderedSet.satisfies(numberOfRequestedElements) else {
					return nil
				}
				return personaDataEntriesOrderedSet.elements
			}(),
			// OH NOOOOOES! TERRIBLE COPY PASTE, alas, we are gonna migrate this into Sargon very soon.
			// so please do forgive me.
			phoneNumbers: { () -> [PersonaDataEntryPhoneNumber]? in
				// Check if incoming Dapp requests the persona data entry kind
				guard
					let numberOfRequestedElements = requested[keyPath: \.numberOfRequestedPhoneNumbers],
					numberOfRequestedElements.quantity > 0
				else {
					// Incoming Dapp request did not ask for access to this kind
					return nil
				}
				let personaDataEntries = personaData[keyPath: \.phoneNumbers]
				let personaDataEntriesOrderedSet = try OrderedSet<PersonaDataEntryPhoneNumber>(validating: personaDataEntries.collection.map(\.value))

				guard personaDataEntriesOrderedSet.satisfies(numberOfRequestedElements) else {
					return nil
				}
				return personaDataEntriesOrderedSet.elements
			}()
		)
	}
}
