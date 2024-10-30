import Foundation
import Sargon

// MARK: - PersonaDataCollectionElement
protocol PersonaDataCollectionElement: Hashable & Identifiable where ID == PersonaDataEntryID {
	associatedtype Value: Hashable
	var value: Value { get }
}

// MARK: - PersonaDataCollectionProtocol
protocol PersonaDataCollectionProtocol<Element> {
	associatedtype Element: PersonaDataCollectionElement
	var collection: [Element] { get }
}

extension PersonaDataCollectionProtocol {
	var first: Element? { collection.first }
	var values: [Element.Value] {
		collection.map(\.value)
	}
}

// MARK: - PersonaDataIdentifiedPhoneNumber + Identifiable
extension PersonaDataIdentifiedPhoneNumber: Identifiable {
	public typealias ID = PersonaDataEntryID
}

// MARK: - PersonaDataIdentifiedEmailAddress + Identifiable
extension PersonaDataIdentifiedEmailAddress: Identifiable {
	public typealias ID = PersonaDataEntryID
}

// MARK: - PersonaDataIdentifiedPhoneNumber + PersonaDataCollectionElement
extension PersonaDataIdentifiedPhoneNumber: PersonaDataCollectionElement {
	typealias Value = PersonaDataEntryPhoneNumber
}

// MARK: - CollectionOfPhoneNumbers + PersonaDataCollectionProtocol
extension CollectionOfPhoneNumbers: PersonaDataCollectionProtocol {
	typealias Element = PersonaDataIdentifiedPhoneNumber
}

// MARK: - CollectionOfEmailAddresses + PersonaDataCollectionProtocol
extension CollectionOfEmailAddresses: PersonaDataCollectionProtocol {
	typealias Element = PersonaDataIdentifiedEmailAddress
}

// MARK: - PersonaDataIdentifiedEmailAddress + PersonaDataCollectionElement
extension PersonaDataIdentifiedEmailAddress: PersonaDataCollectionElement {
	typealias Value = PersonaDataEntryEmailAddress
}

extension Persona {
	static let nameMaxLength = 30
}
