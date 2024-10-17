// MARK: - Sorted
@propertyWrapper
struct Sorted<S: Sequence, Value: Comparable> {
	var wrappedValue: S {
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
	private let fromArray: @Sendable ([S.Element]) -> S

	init(
		wrappedValue: S,
		by keyPath: KeyPath<S.Element, Value>,
		fromArray: @escaping @Sendable ([S.Element]) -> S
	) {
		self._wrappedValue = wrappedValue
		self.keyPath = keyPath
		self.fromArray = fromArray
	}
}

// MARK: Sendable
extension Sorted: Sendable where S: Sendable, Value: Sendable {}

// MARK: Equatable
extension Sorted: Equatable where S: Equatable {
	static func == (lhs: Self, rhs: Self) -> Bool {
		lhs._wrappedValue == rhs._wrappedValue && lhs.keyPath == rhs.keyPath
	}
}

// MARK: Hashable
extension Sorted: Hashable where S: Hashable {
	func hash(into hasher: inout Hasher) {
		hasher.combine(_wrappedValue)
		hasher.combine(keyPath)
	}
}

// MARK: Default Conformances

extension Sorted {
	init<E>(
		wrappedValue: S,
		by keyPath: KeyPath<E, Value>
	) where S == [E] {
		self._wrappedValue = wrappedValue
		self.keyPath = keyPath
		self.fromArray = { $0 }
	}
}

extension Sorted {
	init<E>(
		wrappedValue: S,
		by keyPath: KeyPath<E, Value>
	) where S == IdentifiedArrayOf<E>, E: Identifiable {
		self._wrappedValue = wrappedValue
		self.keyPath = keyPath
		self.fromArray = { IdentifiedArray(uncheckedUniqueElements: $0) }
	}
}
