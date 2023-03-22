import Foundation

// MARK: - Sorted
@propertyWrapper
public struct Sorted<S: Sequence, Value: Comparable> {
	public var wrappedValue: S {
		get {
			fromArray(
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
	private let fromArray: ([S.Element]) -> S

	@_spi(Sorted)
	public init(
		wrappedValue: S,
		by keyPath: KeyPath<S.Element, Value>,
		fromArray: @escaping ([S.Element]) -> S
	) {
		self._wrappedValue = wrappedValue
		self.keyPath = keyPath
		self.fromArray = fromArray
	}
}

// MARK: Equatable
extension Sorted: Equatable where S: Equatable {
	public static func == (lhs: Self, rhs: Self) -> Bool {
		lhs._wrappedValue == rhs._wrappedValue && lhs.keyPath == rhs.keyPath
	}
}

// MARK: Hashable
extension Sorted: Hashable where S: Hashable {
	public func hash(into hasher: inout Hasher) {
		hasher.combine(_wrappedValue)
		hasher.combine(keyPath)
	}
}

// MARK: Default Conformances

import IdentifiedCollections

extension Sorted {
	public init<E>(
		wrappedValue: S,
		by keyPath: KeyPath<E, Value>
	) where S == [E] {
		self._wrappedValue = wrappedValue
		self.keyPath = keyPath
		self.fromArray = { $0 }
	}
}

extension Sorted {
	public init<E>(
		wrappedValue: S,
		by keyPath: KeyPath<E, Value>
	) where S == IdentifiedArrayOf<E>, E: Identifiable {
		self._wrappedValue = wrappedValue
		self.keyPath = keyPath
		self.fromArray = IdentifiedArray.init(uniqueElements:)
	}
}
