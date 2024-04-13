import Foundation
import Sargon

// MARK: - PersonaDataCollectionProtocol
public protocol PersonaDataCollectionProtocol {
	associatedtype Element: Hashable & Identifiable
	var first: Element? { get }
}

extension PersonaDataCollectionProtocol {
	public var first: Element? {
		sargonProfileFinishMigrateAtEndOfStage1()
	}
}

// MARK: - Sargon.PersonaDataEntryName + CustomStringConvertible
extension Sargon.PersonaDataEntryName: CustomStringConvertible {
	public var description: String {
		sargonProfileFinishMigrateAtEndOfStage1()
	}
}

// MARK: - Sargon.PersonaDataIdentifiedPhoneNumber + Identifiable
extension Sargon.PersonaDataIdentifiedPhoneNumber: Identifiable {
	public typealias ID = PersonaDataEntryID
}

// MARK: - Sargon.PersonaDataIdentifiedEmailAddress + Identifiable
extension Sargon.PersonaDataIdentifiedEmailAddress: Identifiable {
	public typealias ID = PersonaDataEntryID
}

// MARK: - Sargon.CollectionOfPhoneNumbers + PersonaDataCollectionProtocol
extension Sargon.CollectionOfPhoneNumbers: PersonaDataCollectionProtocol {
	public typealias Element = Sargon.PersonaDataIdentifiedPhoneNumber
}

// MARK: - Sargon.CollectionOfEmailAddresses + PersonaDataCollectionProtocol
extension Sargon.CollectionOfEmailAddresses: PersonaDataCollectionProtocol {
	public typealias Element = Sargon.PersonaDataIdentifiedEmailAddress
}
