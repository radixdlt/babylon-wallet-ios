import Foundation

typealias ArbitraryDataField = ArbitraryDataFieldView.Field

// MARK: - ArbitraryDataFieldView.Field
extension ArbitraryDataFieldView {
	struct Field: Hashable, Sendable {
		let kind: Kind
		let name: String
		let isLocked: Bool
	}
}

// MARK: - ArbitraryDataFieldView.Field.Kind
extension ArbitraryDataFieldView.Field {
	enum Kind: Hashable, Sendable {
		case primitive(String)
		case truncated(String)
		case complex
		case url(URL)
		case address(LedgerIdentifiable.Address)
		case decimal(Decimal192)
		case `enum`(variant: String)
		case id(NonFungibleLocalId)
		case instant(Date)
	}
}

// MARK: - ArbitraryDataFieldView.Action
extension ArbitraryDataFieldView {
	public enum Action: Hashable, Sendable {
		case urlTapped(URL)
	}
}
