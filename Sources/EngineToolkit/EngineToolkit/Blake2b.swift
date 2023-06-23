import Foundation

// MARK: - Blake2b
public struct Blake2b {
	private init() {}

	public static func hash(data: Data) throws -> HashedData {
		let request = HashRequest(payload: data.hex)
		let response = RadixEngine.instance.hashRequest(request: request)
		let hex = try response.get().value
		return try .init(hex: hex)
	}

	#if DEBUG
	fileprivate static func hash(hex: String) throws -> String {
		let request = HashRequest(payload: hex)
		let response = RadixEngine.instance.hashRequest(request: request)
		return try response.get().value
	}
	#endif
}

/// Calls `Blake2b.hash`
public func blake2b(data: some DataProtocol) throws -> HashedData {
	try Blake2b.hash(data: Data(data))
}

public func blake2b(data: Data) throws -> HashedData {
	try Blake2b.hash(data: data)
}

#if DEBUG
public func blake2b(_ hex: String) throws -> String {
	try Blake2b.hash(hex: hex)
}
#endif
