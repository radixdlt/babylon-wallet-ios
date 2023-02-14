extension Collection where Element: Identifiable {
	public func first(by id: Element.ID) -> Element? {
		first(where: { $0.id == id })
	}
}
