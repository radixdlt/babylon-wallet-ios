import ComposableArchitecture
import Foundation

// MARK: - Loadable
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

 	 var body: some View {
 		 switch value {
 		 case .notLoaded:
 			 // Shimmer
 		 case .loading:
 			 // Animated shimmer or spinner
 		 case let .loaded(result):
 			 switch result {
 			 case .success(let value):
 				 content(value)
 			 case .failure:
 				 // Error message or error color
 			 }
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
public enum Loadable<Value> {
	case notLoaded
	case loading
	case loaded(TaskResult<Value>)

	public subscript<T>(dynamicMember keyPath: KeyPath<Value, T>) -> Loadable<T> {
		switch self {
		case .notLoaded:
			return .notLoaded
		case .loading:
			return .loading
		case let .loaded(result):
			switch result {
			case let .success(value):
				return .loaded(.success(value[keyPath: keyPath]))
			case let .failure(error):
				return .loaded(.failure(error))
			}
		}
	}

	public init(wrappedValue: Value?) {
		self.init(wrappedValue)
	}

	public init(_ value: Value?) {
		if let value {
			self = .loaded(.success(value))
		} else {
			self = .notLoaded
		}
	}

	public init(_ error: Error) {
		self = .loaded(.failure(error))
	}

	public var projectedValue: Self {
		get { self }
		set { self = newValue }
	}

	public var wrappedValue: Value? {
		get {
			guard case let .loaded(.success(value)) = self else { return nil }
			return value
		}
		set {
			self = .init(newValue)
		}
	}
}

// MARK: Equatable
extension Loadable: Equatable where Value: Equatable {}

// MARK: Hashable
extension Loadable: Hashable where Value: Hashable {}
