import ComposableArchitecture
import Foundation

// MARK: - UserDefaultsClient
public struct UserDefaultsClient {
	public var boolForKey: (String) -> Bool
	public var dataForKey: (String) -> Data?
	public var doubleForKey: (String) -> Double
	public var integerForKey: (String) -> Int
	public var remove: (String) -> Effect<Never, Never>
	public var setBool: (Bool, String) -> Effect<Never, Never>
	public var setData: (Data?, String) -> Effect<Never, Never>
	public var setDouble: (Double, String) -> Effect<Never, Never>
	public var setInteger: (Int, String) -> Effect<Never, Never>

	public static let `default`: UserDefaultsClient = .init(
		boolForKey: { _ in true },
		dataForKey: { _ in nil },
		doubleForKey: { _ in Double() },
		integerForKey: { _ in Int() },
		remove: { _ in .none },
		setBool: { _, _ in .none },
		setData: { _, _ in .none },
		setDouble: { _, _ in .none },
		setInteger: { _, _ in .none }
	)
}

private extension UserDefaultsClient {
	func setString(_ string: String, forKey key: String, encoding: String.Encoding = .utf8) -> Effect<Never, Never> {
		let data = string.data(using: encoding)!
		return setData(data, key)
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

	func setHasShownFirstLaunchOnboarding(_ bool: Bool) -> Effect<Never, Never> {
		setBool(bool, hasShownFirstLaunchOnboardingKey)
	}

	func setProfileName(_ name: String) -> Effect<Never, Never> {
		setString(name, forKey: profileNameKey)
	}

	func removeProfileName() -> Effect<Never, Never> {
		remove(profileNameKey)
	}

	var profileName: String? {
		stringForKey(profileNameKey)
	}
}

let hasShownFirstLaunchOnboardingKey = "hasShownFirstLaunchOnboardingKey"
let profileNameKey = "profileNameKey"
