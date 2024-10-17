extension IdentifiedArrayOf {
	func appending(_ element: Element) -> Self {
		var copy = self
		copy.append(element)
		return copy
	}
}

// MARK: - ForEachStatic
/// A wrapper around ForEach that can be used with **static** collections of elements that don't conform to `Identifiable`
struct ForEachStatic<Elements: RandomAccessCollection, Content: View>: View {
	let elements: [OffsetIdentified<Elements.Element>]
	let content: (OffsetIdentified<Elements.Element>) -> Content

	init(_ elements: Elements, content: @escaping (Elements.Element) -> Content) {
		self.elements = elements.identifiablyEnumerated()
		self.content = { content($0.element) }
	}

	var body: some View {
		ForEach(elements, content: content)
	}
}

extension Collection {
	func identifiablyEnumerated() -> [OffsetIdentified<Element>] {
		enumerated().map(OffsetIdentified.init)
	}
}

// MARK: - OffsetIdentified
struct OffsetIdentified<Element>: Identifiable {
	var id: Int { offset }

	let offset: Int
	let element: Element
}

// MARK: Equatable
extension OffsetIdentified: Equatable where Element: Equatable {}

// MARK: Hashable
extension OffsetIdentified: Hashable where Element: Hashable {}

// MARK: Sendable
extension OffsetIdentified: Sendable where Element: Sendable {}

extension OffsetIdentified where Element: Collection {
	var isEmpty: Bool { element.isEmpty }
}
