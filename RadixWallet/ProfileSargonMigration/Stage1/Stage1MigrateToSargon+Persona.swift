import Foundation
import Sargon

// MARK: - Sargon.Persona + EntityBaseProtocol
extension Sargon.Persona: EntityBaseProtocol {}

extension PersonaData.Entry.Kind {
	public var title: String {
		switch self {
		case .fullName:
			L10n.AuthorizedDapps.PersonaDetails.fullName
		case .emailAddress:
			"Email Address"
		case .phoneNumber:
			"Phone Number"
		}
	}
}

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

// MARK: - Sargon.PersonaDataIdentifiedPhoneNumber + Identifiable
extension Sargon.PersonaDataIdentifiedPhoneNumber: Identifiable {
	public typealias ID = PersonaDataEntryID
}

// MARK: - Sargon.PersonaDataIdentifiedEmailAddress + Identifiable
extension Sargon.PersonaDataIdentifiedEmailAddress: Identifiable {
	public typealias ID = PersonaDataEntryID
}

// MARK: - PersonaDataIdentifiedPhoneNumber + PersonaDataCollectionElement
extension PersonaDataIdentifiedPhoneNumber: PersonaDataCollectionElement {
	public typealias Value = PersonaDataEntryPhoneNumber
}

// MARK: - Sargon.CollectionOfPhoneNumbers + PersonaDataCollectionProtocol
extension Sargon.CollectionOfPhoneNumbers: PersonaDataCollectionProtocol {
	public typealias Element = Sargon.PersonaDataIdentifiedPhoneNumber
}

// MARK: - Sargon.CollectionOfEmailAddresses + PersonaDataCollectionProtocol
extension Sargon.CollectionOfEmailAddresses: PersonaDataCollectionProtocol {
	public typealias Element = Sargon.PersonaDataIdentifiedEmailAddress
}

// MARK: - PersonaDataIdentifiedEmailAddress + PersonaDataCollectionElement
extension PersonaDataIdentifiedEmailAddress: PersonaDataCollectionElement {
	public typealias Value = PersonaDataEntryEmailAddress
}
