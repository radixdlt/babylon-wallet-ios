// swiftformat:disable all
/**
 Loadable represents a value that can be either not loaded, loading or loaded. In the case when it has been loaded, that may or may not have succeeded.
 Typically it would contain the result of calling a remote API.
 if we have a `State`:
 ```
 struct State {
     @Loadable
     var user: User? = nil
 }
 ```
 Then we can access an optional user instance as normal: `if let theUser = state.user { ... }` which will provide the user if it has been successfully loaded.
 In some UI situations we might want to indicate if a value is still loading, failed to load etc, and then we can use something like the `LoadableView`:
 ```
 struct LoadableView<Value, Content: View>: View {
     let value: Loadable<Value>
     let content: (Value) -> Content

 // MARK: - Loadable
     var body: some View {
         switch value {
         case .idle:
             // Shimmer
         case .loading:
             // Animated shimmer or spinner
         case .success(let value):
             content(value)
         case .failure:
             // Error message or error color
         }
     }
 }
 ```
 The way it is used, given some `UserView` which expects a `User`, is as follows:
 ```
 var body: some view {
     LoadableView(value: state.$user) { user in
         UserView(user: user)
     }
 }
 ```
 The loading state of the user can be preserved when accessing its properties, if desired:
 ```
 var body: some view {
     LoadableView(value: state.$user.userName.firstName) { firstName in
         Text(firstName)
     }
 }
 ```
 where `state.$user.userName.firstName` is a `Loadable<String>`, similar to how `Binding` works.
 */

@propertyWrapper
@dynamicMemberLookup
enum Loadable<Value> {
	case idle
	case loading
	case success(Value)
	case failure(Error)

	subscript<T>(dynamicMember keyPath: KeyPath<Value, T>) -> Loadable<T> {
		map { $0[keyPath: keyPath] }
	}

	init(wrappedValue: Value?) {
		self.init(wrappedValue)
	}

	init(_ value: Value?) {
		if let value {
			self = .success(value)
		} else {
			self = .idle
		}
	}

	init(_ error: Error) {
		self = .failure(error)
	}

	var projectedValue: Self {
		get { self }
		set { self = newValue }
	}

	var wrappedValue: Value? {
		get {
			guard case let .success(value) = self else { return nil }
			return value
		}
		set {
			self = .init(newValue)
		}
	}

	var isLoading: Bool {
		if case .loading = self {
			return true
		}
		return false
	}

    var isSuccess: Bool {
        if case .success = self {
            return true
        }
        return false
    }

    var didLoad: Bool {
        switch self {
        case .success, .failure:
            return true
        case .idle, .loading:
            return false
        }
    }
}

extension Loadable {
	init(result: TaskResult<Value>) {
		switch result {
		case let .success(value):
			self = .success(value)
		case let .failure(error):
			self = .failure(error)
		}
	}
}

// MARK: Equatable
extension Loadable: Equatable where Value: Equatable {
	static func == (lhs: Self, rhs: Self) -> Bool {
		switch (lhs, rhs) {
		case let (.success(lhs), .success(rhs)):
			lhs == rhs
		case let (.failure(lhs), .failure(rhs)):
			_isEqual(lhs, rhs) ?? false
		case (.idle, .idle):
			true
		case (.loading, .loading):
			true
		default:
			false
		}
	}
}

// MARK: Equatable helpers

private func _isEqual(_ lhs: Any, _ rhs: Any) -> Bool? {
	(lhs as? any Equatable)?.isEqual(other: rhs)
}

extension Equatable {
	fileprivate func isEqual(other: Any) -> Bool {
		self == other as? Self
	}
}

// MARK: - Loadable + Hashable
extension Loadable: Hashable where Value: Hashable {
	func hash(into hasher: inout Hasher) {
		switch self {
		case .idle:
			hasher.combine(0)
		case .loading:
			hasher.combine(1)
		case let .success(value):
			hasher.combine(value)
			hasher.combine(2)
		case let .failure(error):
			if let error = (error as Any) as? AnyHashable {
				hasher.combine(error)
				hasher.combine(4)
			}
		}
	}
}

// MARK: - Loadable + Sendable
extension Loadable: Sendable where Value: Sendable {}

extension Loadable {
	func map<NewValue>(_ transform: (Value) -> NewValue) -> Loadable<NewValue> {
		flatMap { .success(transform($0)) }
	}

    func errorFallback(_ fallback: Value) -> Loadable<Value> {
        if case .failure = self {
            return .success(fallback)
        }
        return self
    }

	func filter(by predicate: (Value.Element) -> Bool) -> Loadable<[Value.Element]> where Value: Sequence {
		switch self {
		case .idle:
			return .idle
		case .loading:
			return .loading
		case let .success(value):
			return .success(value.filter(predicate))
		case let .failure(error):
			return .failure(error)
		}
	}
    
    func compactMapValue<ResultElement>(by predicate: (Value.Element) -> ResultElement?) -> Loadable<[ResultElement]> where Value: Sequence {
        switch self {
        case .idle:
            return .idle
        case .loading:
            return .loading
        case let .success(value):
            return .success(value.compactMap(predicate))
        case let .failure(error):
            return .failure(error)
        }
    }

	/// Transforms a Loadable<Wrapped?> to Loadable<Wrapped>?
	func unwrap<Wrapped>() -> Loadable<Wrapped>? where Value == Wrapped? {
		switch self {
		case .idle:
			return .idle
		case .loading:
			return .loading
		case let .success(value):
			guard let value else {
				return nil
			}
			return .success(value)
		case let .failure(error):
			return .failure(error)
		}
	}

	func first(where predicate: (Value.Element) -> Bool) -> Loadable<Value.Element?> where Value: Sequence {
		switch self {
		case .idle:
			return .idle
		case .loading:
			return .loading
		case let .success(value):
			return .success(value.first(where: predicate))
		case let .failure(error):
			return .failure(error)
		}
	}

	func flatMap<NewValue>(_ transform: (Value) -> Loadable<NewValue>) -> Loadable<NewValue> {
		switch self {
		case .idle:
			.idle
		case .loading:
			.loading
		case let .success(value):
			transform(value)
		case let .failure(error):
			.failure(error)
		}
	}

	func flatMap<NewValue>(_ transform: (Value) async -> Loadable<NewValue>) async -> Loadable<NewValue> {
		switch self {
		case .idle:
			.idle
		case .loading:
			.loading
		case let .success(value):
			await transform(value)
		case let .failure(error):
			.failure(error)
		}
	}

	func concat<OtherValue>(_ other: Loadable<OtherValue>) -> Loadable<(Value, OtherValue)> {
		switch (self, other) {
		case (.idle, _), (_, .idle):
			.idle
		case (.loading, _), (_, .loading):
			.loading
		case let (.success(thisValue), .success(otherValue)):
			.success((thisValue, otherValue))
		case let (.failure(error), _), let (_, .failure(error)):
			.failure(error)
		}
	}

    func flatten<InnerValue>() -> Loadable<InnerValue> where Value == Loadable<InnerValue> {
        switch self {
        case .idle:
            return .idle
        case .loading:
            return .loading
        case let .success(value):
            return value
        case .failure(let error):
            return .failure(error)
        }
    }

    func reduce(_ other: Loadable<Value>, join: (Value, Value) -> Value) -> Loadable<Value> {
        concat(other).map(join)
    }

    mutating func mutateValue(_ mutate: (inout Value) -> Void) {
        switch self {
        case .idle, .loading, .failure:
            return
        case var .success(value):
            mutate(&value)
            self = .success(value)
        }
    }

    /// Refreshes from other Loadable by taking into account the current `success` state.
    /// This is meant to preserve the `success` state while other Loadable is `loading` or `failed`.
    mutating func refresh(
        from other: Loadable<Value>,
        valueChangeMap: (_ old: Value, _ new: Value) -> Value = { _, new in new }
    ) where Value: Equatable {
        switch (self, other) {
        // Update to success if no current value
        case let (.idle, .success(otherValue)),
            let (.loading, .success(otherValue)),
            let (.failure, .success(otherValue)):

            self = .success(otherValue)

        // Update to new value only if it changed
        case let (.success(oldValue), .success(newValue)):
            if oldValue != newValue {
                self = .success(valueChangeMap(oldValue, newValue))
            }

        // If current state is success, don't update if `other` is loading or failed
        case (.success, _):
            break

        case (.loading, .loading),
            (.idle, .idle):
            break

        // If current state is other than .success
        case let (_, other):
            self = other
        }
    }
}

extension Array {
    func reduce<Value>(_ join: (Value, Value) -> Value) -> Loadable<Value>? where Element == Loadable<Value> {
        guard var result = first else {
            return nil
        }

        for item in dropFirst() {
            result = result.reduce(item, join: join)
        }
        return result
    }
}

extension Loadable {
	/// Extract the given field either from the prefetched value or from the loaded value
	func get<Field>(_ keyPath: KeyPath<Value, Field>, prefetched: Value?) -> Loadable<Field> {
		guard let prefetchedField = prefetched?[keyPath: keyPath] else {
			return map { $0[keyPath: keyPath] }
		}
		return .success(prefetchedField)
	}
}

// swiftformat:enable all
