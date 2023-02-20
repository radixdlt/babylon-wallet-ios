import Foundation

// MARK: - Loadable
@propertyWrapper
@dynamicMemberLookup
public enum Loadable<Value> {
	case notLoaded
	case loading
	case loaded(Value)
	case failed

	public subscript<T>(dynamicMember keyPath: KeyPath<Value, T>) -> Loadable<T> {
		switch self {
		case .notLoaded:
			return .notLoaded
		case .loading:
			return .loading
		case let .loaded(value):
			return .loaded(value[keyPath: keyPath])
		case .failed:
			return .failed
		}
	}

	public init(wrappedValue: Value?) {
		if let wrappedValue {
			self = .loaded(wrappedValue)
		} else {
			self = .notLoaded
		}
	}

	public var projectedValue: Self {
		get { self }
		set { self = newValue }
	}

	public var wrappedValue: Value? {
		get {
			guard case let .loaded(value) = self else { return nil }
			return value
		}
		set {
			if let newValue {
				self = .loaded(newValue)
			} else {
				self = .notLoaded
			}
		}
	}
}

// MARK: Equatable
extension Loadable: Equatable where Value: Equatable {}

// MARK: Hashable
extension Loadable: Hashable where Value: Hashable {}
