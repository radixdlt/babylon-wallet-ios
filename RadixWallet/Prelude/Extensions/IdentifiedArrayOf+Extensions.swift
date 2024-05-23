extension IdentifiedArrayOf {
	public func appending(_ element: Element) -> Self {
		var copy = self
		copy.append(element)
		return copy
	}
}

// MARK: - ForEachStatic
/// A wrapper around ForEach that can be used with **static** collections of elements that don't conform to `Identifiable`
public struct ForEachStatic<Elements: RandomAccessCollection, Content: View>: View {
	public let elements: [OffsetIdentified<Elements.Element>]
	public let content: (OffsetIdentified<Elements.Element>) -> Content

	public init(_ elements: Elements, content: @escaping (Elements.Element) -> Content) {
		self.elements = elements.identifiablyEnumerated()
		self.content = { content($0.element) }
	}

	public var body: some View {
		ForEach(elements, content: content)
	}
}

extension Collection {
	public func identifiablyEnumerated() -> [OffsetIdentified<Element>] {
		enumerated().map(OffsetIdentified.init)
	}
}

// MARK: - OffsetIdentified
public struct OffsetIdentified<Element>: Identifiable {
	public var id: Int { offset }

	public let offset: Int
	public let element: Element
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
