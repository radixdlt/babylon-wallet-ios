@_exported import Validated

// MARK: - Validation
@propertyWrapper
@dynamicMemberLookup
public struct Validation<Value, Error> {
	@_spi(Validation) public var rawValue: Value?
	private let onNil: () -> Error?
	private let rules: [ValidationRule<Value, Error>]
	private let exceptions: [(Value) -> Bool]

	public init(
		wrappedValue rawValue: Value?,
		onNil: @escaping @autoclosure () -> Error?,
		rules: [ValidationRule<Value, Error>],
		exceptions: [(Value) -> Bool] = []
	) {
		self.rawValue = rawValue
		self.onNil = onNil
		self.rules = rules
		self.exceptions = exceptions
	}

	public var projectedValue: Self {
		self
	}

	public var validated: Validated<Value, Error>? {
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

	public subscript<T>(dynamicMember keyPath: KeyPath<Validated<Value, Error>, T?>) -> T? {
		validated?[keyPath: keyPath]
	}

	public var wrappedValue: Value? {
		get {
			validated?.value
		}
		set {
			rawValue = newValue
		}
	}
}

// MARK: Equatable
extension Validation: Equatable where Value: Equatable, Error: Equatable {
	public static func == (lhs: Self, rhs: Self) -> Bool {
		lhs.projectedValue == rhs.projectedValue
	}
}

// MARK: Hashable
extension Validation: Hashable where Value: Hashable, Error: Hashable {
	public func hash(into hasher: inout Hasher) {
		hasher.combine(projectedValue)
	}
}

// MARK: - Validated + Hashable
extension Validated: Hashable where Value: Hashable, Error: Hashable {
	public func hash(into hasher: inout Hasher) {
		switch self {
		case let .valid(value):
			hasher.combine(value)
		case let .invalid(errors):
			hasher.combine(errors)
		}
	}
}

// MARK: - ValidationRule
public struct ValidationRule<Value, Error> {
	let validate: (Value) -> Error?

	public static func `if`(
		_ condition: @escaping (Value) -> Bool,
		error: @autoclosure @escaping () -> Error
	) -> Self {
		ValidationRule {
			if condition($0) {
				return error()
			} else {
				return nil
			}
		}
	}

	public static func unless(
		_ condition: @escaping (Value) -> Bool,
		error: @autoclosure @escaping () -> Error
	) -> Self {
		ValidationRule {
			if !condition($0) {
				return error()
			} else {
				return nil
			}
		}
	}
}

// MARK: - ValidationError
// public protocol ValidationError<Value>: CaseIterable {
//	associatedtype Value
//
//	var condition: (Value) -> Bool { get }
// }

// extension Validation where Error: ValidationError<Value> {
//	public init(wrappedValue: Value? = nil) {
//		self.init(wrappedValue: wrappedValue, rules: Error.rules)
//	}
// }

// extension ValidationError {
//	public static var rules: [ValidationRule<Value, Self>] {
//		allCases.map { error in
//			ValidationRule { value in
//				error.condition(value) ? error : nil
//			}
//		}
//	}
// }

// public typealias ValidationRuleOf<Error: ValidationError> = ValidationRule<Error.Value, Error>
