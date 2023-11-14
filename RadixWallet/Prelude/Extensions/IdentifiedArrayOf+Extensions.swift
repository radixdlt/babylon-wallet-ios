extension IdentifiedArrayOf {
	public func appending(_ element: Element) -> Self {
		var copy = self
		copy.append(element)
		return copy
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
