public extension Identifiable where Self: RawRepresentable, RawValue: Hashable {
	var id: RawValue {
		rawValue
	}
}

public extension Collection where Element: Identifiable {
	func first(by id: Element.ID) -> Element? {
		first(where: { $0.id == id })
	}
}
