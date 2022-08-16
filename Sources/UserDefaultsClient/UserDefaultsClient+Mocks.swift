import Foundation

public extension UserDefaultsClient {
	static let noop = Self(
		boolForKey: { _ in false },
		dataForKey: { _ in nil },
		doubleForKey: { _ in 0 },
		integerForKey: { _ in 0 },
		remove: { _ in },
		setBool: { _, _ in },
		setData: { _, _ in },
		setDouble: { _, _ in },
		setInteger: { _, _ in }
	)
}

#if DEBUG
import Foundation
import XCTestDynamicOverlay

public extension UserDefaultsClient {
	static let unimplemented = Self(
		boolForKey: XCTUnimplemented("\(Self.self).boolForKey", placeholder: false),
		dataForKey: XCTUnimplemented("\(Self.self).dataForKey", placeholder: nil),
		doubleForKey: XCTUnimplemented("\(Self.self).doubleForKey", placeholder: 0),
		integerForKey: XCTUnimplemented("\(Self.self).integerForKey", placeholder: 0),
        remove: XCTUnimplemented("\(Self.self).remove"),
		setBool: XCTUnimplemented("\(Self.self).setBool"),
		setData: XCTUnimplemented("\(Self.self).setData"),
		setDouble: XCTUnimplemented("\(Self.self).setDouble"),
		setInteger: XCTUnimplemented("\(Self.self).setInteger")
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
#endif
