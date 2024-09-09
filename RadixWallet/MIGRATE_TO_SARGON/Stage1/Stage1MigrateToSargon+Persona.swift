import Foundation
import Sargon

// MARK: - PersonaDataCollectionElement
public protocol PersonaDataCollectionElement: Hashable & Identifiable where ID == PersonaDataEntryID {
	associatedtype Value: Hashable
	var value: Value { get }
}

// MARK: - PersonaDataCollectionProtocol
public protocol PersonaDataCollectionProtocol<Element> {
	associatedtype Element: PersonaDataCollectionElement
	var collection: [Element] { get }
}

extension PersonaDataCollectionProtocol {
	public var first: Element? { collection.first }
	public var values: [Element.Value] {
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
	public typealias Value = PersonaDataEntryPhoneNumber
}

// MARK: - CollectionOfPhoneNumbers + PersonaDataCollectionProtocol
extension CollectionOfPhoneNumbers: PersonaDataCollectionProtocol {
	public typealias Element = PersonaDataIdentifiedPhoneNumber
}

// MARK: - CollectionOfEmailAddresses + PersonaDataCollectionProtocol
extension CollectionOfEmailAddresses: PersonaDataCollectionProtocol {
	public typealias Element = PersonaDataIdentifiedEmailAddress
}

// MARK: - PersonaDataIdentifiedEmailAddress + PersonaDataCollectionElement
extension PersonaDataIdentifiedEmailAddress: PersonaDataCollectionElement {
	public typealias Value = PersonaDataEntryEmailAddress
}

extension Persona {
	public static let nameMaxLength = 30
}
