//
//  File.swift
//
//
//  Created by Alexander Cyon on 2022-06-30.
//

import Foundation

public extension UserDefaultsClient {
	static let noop = Self(
		boolForKey: { _ in false },
		dataForKey: { _ in nil },
		doubleForKey: { _ in 0 },
		integerForKey: { _ in 0 },
		remove: { _ in .none },
		setBool: { _, _ in .none },
		setData: { _, _ in .none },
		setDouble: { _, _ in .none },
		setInteger: { _, _ in .none }
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
		remove: XCTUnimplemented("\(Self.self).remove", placeholder: .none),
		setBool: XCTUnimplemented("\(Self.self).setBool", placeholder: .none),
		setData: XCTUnimplemented("\(Self.self).setData", placeholder: .none),
		setDouble: XCTUnimplemented("\(Self.self).setDouble", placeholder: .none),
		setInteger: XCTUnimplemented("\(Self.self).setInteger", placeholder: .none)
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
