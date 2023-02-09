public extension Collection where Element: Identifiable {
	func first(by id: Element.ID) -> Element? {
		first(where: { $0.id == id })
	}
}
