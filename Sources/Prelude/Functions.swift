import Foundation

public func with<T>(
	_ initial: T,
	update: (inout T) throws -> Void
) rethrows -> T {
	var value = initial
	try update(&value)
	return value
}

public func not<T>(
	_ f: @escaping (T) -> Bool
) -> (T) -> Bool {
	{ input in
		!f(input)
	}
}

/// You can use `identity` instead of `{ $0 }`
public func identity<T>(_ t: T) -> T {
	t
}
