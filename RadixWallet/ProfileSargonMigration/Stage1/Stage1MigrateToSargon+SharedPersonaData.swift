import Foundation
import Sargon

extension SharedPersonaData {
	public static var `default`: Self {
		sargonProfileFinishMigrateAtEndOfStage1()
	}

	public var entryIDs: Set<PersonaDataEntryID> {
//			var ids: [PersonaDataEntryID] = [
//				name, dateOfBirth, companyName,
//			].compactMap { $0 }
//			ids.append(contentsOf: emailAddresses?.ids ?? [])
//			ids.append(contentsOf: phoneNumbers?.ids ?? [])
//			ids.append(contentsOf: urls?.ids ?? [])
//			ids.append(contentsOf: postalAddresses?.ids ?? [])
//			ids.append(contentsOf: creditCards?.ids ?? [])
//
//			// The only purpose of this switch is to make sure we get a compilation error when we add a new PersonaData.Entry kind, so
//			// we do not forget to handle it here.
//			switch PersonaData.Entry.Kind.fullName {
//			case .fullName, .dateOfBirth, .companyName, .emailAddress, .phoneNumber, .url, .postalAddress, .creditCard: break
//			}
//
//			return Set(ids)
		sargonProfileFinishMigrateAtEndOfStage1()
	}
}
