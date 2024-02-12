import Foundation

// MARK: - Instructions
public struct Instructions: DummySargon {
	public func asStr() -> String {
		sargon()
	}

	public func networkId() -> UInt8 {
		sargon()
	}

	public static func fromString(string: Any, networkId: UInt8) -> Self {
		sargon()
	}
}
