import Foundation

// MARK: - Sorted
@propertyWrapper
public struct Sorted<S: Sequence & ArrayRepresentable, Value: Comparable> {
	public var wrappedValue: S {
		get {
			S(
				_wrappedValue.sorted(by: { lhs, rhs in
					lhs[keyPath: keyPath] < rhs[keyPath: keyPath]
				})
			)
		}
		set {
			_wrappedValue = newValue
		}
	}

	private var _wrappedValue: S
	private let keyPath: KeyPath<S.Element, Value>

	public init(wrappedValue: S, by keyPath: KeyPath<S.Element, Value>) {
		self._wrappedValue = wrappedValue
		self.keyPath = keyPath
	}
}

// MARK: Equatable
extension Sorted: Equatable where S: Equatable {}

// MARK: Hashable
extension Sorted: Hashable where S: Hashable {}

// MARK: - ArrayRepresentable
public protocol ArrayRepresentable {
	associatedtype Element
	init(_ array: [Element])
}

// MARK: - IdentifiedArray + ArrayRepresentable
extension IdentifiedArray: ArrayRepresentable where ID == Element.ID, Element: Identifiable {
	public init(_ array: [Element]) {
		self.init(uniqueElements: array)
	}
}
