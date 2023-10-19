
public func update<T>(
	_ initial: T,
	with: (inout T) throws -> Void
) rethrows -> T {
	var value = initial
	try with(&value)
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

/// Wherever you have to handle `Never`
public func absurd<T>(_ never: Never) -> T {
	switch never {}
}
