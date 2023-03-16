@_exported import Validated

// MARK: - Validation
@propertyWrapper
public struct Validation<Value, Error> {
	@_spi(ValidationInternals) public var rawValue: Value?
	private var rules: [ValidationRule<Value, Error>]

	@_disfavoredOverload
	public init(wrappedValue rawValue: Value? = nil, _ rules: [ValidationRule<Value, Error>]) {
		self.rawValue = rawValue
		self.rules = rules
	}

	public var projectedValue: Validated<Value, Error>? {
		guard let rawValue else {
			return nil
		}
		if let errors = NonEmpty(rawValue: rules.compactMap { $0.validate(rawValue) }) {
			return .invalid(errors)
		} else {
			return .valid(rawValue)
		}
	}

	public var wrappedValue: Value? {
		get {
			projectedValue?.value
		}
		set {
			rawValue = newValue
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
public protocol ValidationError<Value>: CaseIterable {
	associatedtype Value

	var condition: (Value) -> Bool { get }
}

extension Validation where Error: ValidationError<Value> {
	public init(wrappedValue: Value? = nil) {
		self.init(wrappedValue: wrappedValue, Error.rules)
	}
}

extension ValidationError {
	public static var rules: [ValidationRule<Value, Self>] {
		allCases.map { error in
			ValidationRule { value in
				error.condition(value) ? error : nil
			}
		}
	}
}

public typealias ValidationRuleOf<Error: ValidationError> = ValidationRule<Error.Value, Error>

#if canImport(SwiftUI)
import SwiftUI

extension Binding {
	public static func validation<Value, Error>(
		get: @escaping () -> Validation<Value, Error>,
		set: @escaping (Value?) -> Void
	) -> Binding<Value?> {
		.init(get: { get().rawValue }, set: { set($0) })
	}
}
#endif
