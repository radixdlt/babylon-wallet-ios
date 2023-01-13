import Dependencies

// MARK: - UserDefaultsClient
public struct UserDefaultsClient: Sendable {
	public typealias Key = String

	public var stringForKey: @Sendable (Key) -> String?
	public var boolForKey: @Sendable (Key) -> Bool
	public var dataForKey: @Sendable (Key) -> Data?
	public var doubleForKey: @Sendable (Key) -> Double
	public var integerForKey: @Sendable (Key) -> Int
	public var remove: @Sendable (Key) async -> Void
	public var setString: @Sendable (String, Key) async -> Void
	public var setBool: @Sendable (Bool, Key) async -> Void
	public var setData: @Sendable (Data?, Key) async -> Void
	public var setDouble: @Sendable (Double, Key) async -> Void
	public var setInteger: @Sendable (Int, Key) async -> Void
}
