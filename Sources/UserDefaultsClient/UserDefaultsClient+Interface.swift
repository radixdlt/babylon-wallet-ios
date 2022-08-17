import ComposableArchitecture
import Foundation

// MARK: - UserDefaultsClient
public struct UserDefaultsClient {
	public var boolForKey: @Sendable (String) -> Bool
	public var dataForKey: @Sendable (String) -> Data?
	public var doubleForKey: @Sendable (String) -> Double
	public var integerForKey: @Sendable (String) -> Int
	public var remove: @Sendable (String) async -> Void
	public var setBool: @Sendable (Bool, String) async -> Void
	public var setData: @Sendable (Data?, String) async -> Void
	public var setDouble: @Sendable (Double, String) async -> Void
	public var setInteger: @Sendable (Int, String) async -> Void
}

private extension UserDefaultsClient {
	func setString(_ string: String, forKey key: String, encoding: String.Encoding = .utf8) async {
		let data = string.data(using: encoding)!
		await setData(data, key)
	}

	func stringForKey(_ key: String, encoding: String.Encoding = .utf8) -> String? {
		guard let data = dataForKey(key) else {
			return nil
		}
		return String(data: data, encoding: encoding)
	}
}

public extension UserDefaultsClient {
	var hasShownFirstLaunchOnboarding: Bool {
		boolForKey(hasShownFirstLaunchOnboardingKey)
	}

	func setHasShownFirstLaunchOnboarding(_ bool: Bool) async {
		await setBool(bool, hasShownFirstLaunchOnboardingKey)
	}

	func setProfileName(_ name: String) async {
		await setString(name, forKey: profileNameKey)
	}

	func removeProfileName() async {
		await remove(profileNameKey)
	}

	var profileName: String? {
		stringForKey(profileNameKey)
	}
}

let hasShownFirstLaunchOnboardingKey = "hasShownFirstLaunchOnboardingKey"
let profileNameKey = "profileNameKey"
