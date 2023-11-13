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

extension Collection where Element: Identifiable {
	public func identified() throws -> IdentifiedArrayOf<Element> {
		guard Set(map(\.id)).count == count else {
			throw IdentifiedArrayError.clashingIDs
		}
		return .init(uniqueElements: self)
	}

	public func uniqueIdentified() -> IdentifiedArrayOf<Element> {
		.init(uncheckedUniqueElements: self)
	}
}

// MARK: - IdentifiedArrayError
public enum IdentifiedArrayError: Error {
	case clashingIDs
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
