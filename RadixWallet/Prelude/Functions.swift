
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

public func generateElements<Element>(
	start: Element,
	step: (Element) -> Element,
	count: Int,
	shouldInclude: (Element) -> Bool
) -> OrderedSet<Element> where Element: Hashable {
	var next = start
	var elements: OrderedSet<Element> = []
	while elements.count != count {
		defer { next = step(next) }
		guard shouldInclude(next) else { continue }
		elements.append(next)
	}
	assert(elements.count == count)
	return elements
}

public func generateIntegers<Integer>(
	start: Integer,
	count: Int,
	shouldInclude: @escaping (Integer) -> Bool
) -> OrderedSet<Integer> where Integer: FixedWidthInteger {
	generateElements(start: start, step: { $0 + 1 }, count: count, shouldInclude: shouldInclude)
}
