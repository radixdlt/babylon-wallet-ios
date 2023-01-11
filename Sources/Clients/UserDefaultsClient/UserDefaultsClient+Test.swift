import Foundation
import Prelude

public extension DependencyValues {
	var userDefaultsClient: UserDefaultsClient {
		get { self[UserDefaultsClient.self] }
		set { self[UserDefaultsClient.self] = newValue }
	}
}

// MARK: - UserDefaultsClient + TestDependencyKey
extension UserDefaultsClient: TestDependencyKey {
	public static let previewValue = Self.noop

	public static let testValue = Self(
		stringForKey: unimplemented("\(Self.self).stringForKey", placeholder: "dummy string"),
		boolForKey: unimplemented("\(Self.self).boolForKey", placeholder: false),
		dataForKey: unimplemented("\(Self.self).dataForKey", placeholder: nil),
		doubleForKey: unimplemented("\(Self.self).doubleForKey", placeholder: 0),
		integerForKey: unimplemented("\(Self.self).integerForKey", placeholder: 0),
		remove: unimplemented("\(Self.self).remove"),
		setString: unimplemented("\(Self.self).setString"),
		setBool: unimplemented("\(Self.self).setBool"),
		setData: unimplemented("\(Self.self).setData"),
		setDouble: unimplemented("\(Self.self).setDouble"),
		setInteger: unimplemented("\(Self.self).setInteger")
	)
}

public extension UserDefaultsClient {
	static let noop = Self(
		stringForKey: { _ in "dummyString " },
		boolForKey: { _ in false },
		dataForKey: { _ in nil },
		doubleForKey: { _ in 0 },
		integerForKey: { _ in 0 },
		remove: { _ in },
		setString: { _, _ in },
		setBool: { _, _ in },
		setData: { _, _ in },
		setDouble: { _, _ in },
		setInteger: { _, _ in }
	)

	mutating func override(bool: Bool, forKey key: String) {
		boolForKey = { [self] in $0 == key ? bool : self.boolForKey(key) }
	}

	mutating func override(data: Data, forKey key: String) {
		dataForKey = { [self] in $0 == key ? data : self.dataForKey(key) }
	}

	mutating func override(double: Double, forKey key: String) {
		doubleForKey = { [self] in $0 == key ? double : self.doubleForKey(key) }
	}

	mutating func override(integer: Int, forKey key: String) {
		integerForKey = { [self] in $0 == key ? integer : self.integerForKey(key) }
	}
}
