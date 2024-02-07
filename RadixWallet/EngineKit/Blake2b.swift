// MARK: - Blake2b
public struct Blake2b {
	private init() {}

	public static func hash(data: Data) throws -> Data {
		Hash.fromUnhashedBytes(bytes: data).bytes()
	}

	#if DEBUG
	fileprivate static func hash(hex: String) throws -> String {
		try Hash.fromHexString(hash: hex).asStr()
	}
	#endif
}

/// Calls `Blake2b.hash`
public func blake2b(data: some DataProtocol) throws -> Data {
	try Blake2b.hash(data: Data(data))
}

public func blake2b(data: Data) throws -> Data {
	try Blake2b.hash(data: data)
}

#if DEBUG
public func blake2b(_ hex: String) throws -> String {
	try Blake2b.hash(hex: hex)
}
#endif
