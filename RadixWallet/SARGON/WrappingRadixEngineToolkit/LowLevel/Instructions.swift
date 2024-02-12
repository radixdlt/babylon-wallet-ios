import Foundation

// MARK: - Instructions
public struct Instructions: DummySargon {
	public func asStr() -> String {
		panic()
	}

	public func networkId() -> UInt8 {
		panic()
	}

	public static func fromString(string: Any, networkId: UInt8) -> Self {
		panic()
	}
}
