// MARK: - Validation
@propertyWrapper
@dynamicMemberLookup
struct Validation<Value, Error> {
	var rawValue: Value?
	private let onNil: @Sendable () -> Error?
	private let rules: [ValidationRule<Value, Error>]
	private let exceptions: [@Sendable (Value) -> Bool]

	init(
		wrappedValue rawValue: Value?,
		onNil: @autoclosure @escaping @Sendable () -> Error?,
		rules: [ValidationRule<Value, Error>],
		exceptions: [@Sendable (Value) -> Bool] = []
	) {
		self.rawValue = rawValue
		self.onNil = onNil
		self.rules = rules
		self.exceptions = exceptions
	}

	var projectedValue: Self {
		self
	}

	var validated: Validated<Value, Error>? {
		guard let rawValue else {
			if let error = onNil() {
				return .invalid(NonEmptyArray(error))
			} else {
				return nil
			}
		}
		if exceptions.contains(where: { $0(rawValue) }) {
			return .valid(rawValue)
		}
		if let errors = NonEmpty(rawValue: rules.compactMap { $0.validate(rawValue) }) {
			return .invalid(errors)
		} else {
			return .valid(rawValue)
		}
	}

	subscript<T>(dynamicMember keyPath: KeyPath<Validated<Value, Error>, T?>) -> T? {
		validated?[keyPath: keyPath]
	}

	var wrappedValue: Value? {
		get {
			validated?.value
		}
		set {
			rawValue = newValue
		}
	}
}

// MARK: Sendable
extension Validation: Sendable where Value: Sendable, Error: Sendable {}

// MARK: Equatable
extension Validation: Equatable where Value: Equatable {
	static func == (lhs: Self, rhs: Self) -> Bool {
		lhs.rawValue == rhs.rawValue
	}
}

// MARK: Hashable
extension Validation: Hashable where Value: Hashable {
	func hash(into hasher: inout Hasher) {
		hasher.combine(rawValue)
	}
}

// MARK: - ValidationRule
struct ValidationRule<Value, Error> {
	let validate: @Sendable (Value) -> Error?

	static func `if`(
		_ condition: @escaping @Sendable (Value) -> Bool,
		error: @autoclosure @escaping @Sendable () -> Error
	) -> Self {
		ValidationRule {
			if condition($0) {
				error()
			} else {
				nil
			}
		}
	}

	static func unless(
		_ condition: @escaping @Sendable (Value) -> Bool,
		error: @autoclosure @escaping @Sendable () -> Error
	) -> Self {
		ValidationRule {
			if !condition($0) {
				error()
			} else {
				nil
			}
		}
	}
}

// MARK: Sendable
extension ValidationRule: Sendable where Value: Sendable, Error: Sendable {}
