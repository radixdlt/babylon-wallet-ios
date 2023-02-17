import Prelude

// MARK: - iOS
public enum iOS {}
public extension iOS {
	static func getDeviceDescription() -> NonEmpty<String> {
		.init(rawValue: "iPhone 14 Pro Max")!
	}
}
