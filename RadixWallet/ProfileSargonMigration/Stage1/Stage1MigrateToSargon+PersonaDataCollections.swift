import Foundation
import Sargon

// MARK: - PersonaDataCollectionProtocol
public protocol PersonaDataCollectionProtocol {
	associatedtype Element: Hashable & Identifiable
	var first: Element? { get }
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
	public var first: Element? {
		self.collection.first
	}
}

// MARK: - Sargon.CollectionOfEmailAddresses + PersonaDataCollectionProtocol
extension Sargon.CollectionOfEmailAddresses: PersonaDataCollectionProtocol {
	public typealias Element = Sargon.PersonaDataIdentifiedEmailAddress
	public var first: Element? {
		self.collection.first
	}
}
