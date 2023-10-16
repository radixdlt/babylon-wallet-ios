// NB: variadic generics should make these a single function instead of several overloads

public func unwrap<A, B>(_ a: A?, _ b: B?) -> (A, B)? {
	guard let a, let b else { return nil }
	return (a, b)
}

public func unwrap<A, B, C>(_ a: A?, _ b: B?, _ c: C?) -> (A, B, C)? {
	guard let a, let b, let c else { return nil }
	return (a, b, c)
}

public func unwrap<A, B, C, D>(_ a: A?, _ b: B?, _ c: C?, _ d: D?) -> (A, B, C, D)? {
	guard let a, let b, let c, let d else { return nil }
	return (a, b, c, d)
}

public func unwrap<A, B, C, D, E>(_ a: A?, _ b: B?, _ c: C?, _ d: D?, _ e: E?) -> (A, B, C, D, E)? {
	guard let a, let b, let c, let d, let e else { return nil }
	return (a, b, c, d, e)
}

public func unwrap<A, B, C, D, E, F>(_ a: A?, _ b: B?, _ c: C?, _ d: D?, _ e: E?, _ f: F?) -> (A, B, C, D, E, F)? {
	guard let a, let b, let c, let d, let e, let f else { return nil }
	return (a, b, c, d, e, f)
}
