import Dependencies

// MARK: - UserDefaultsClient + DependencyKey
extension UserDefaultsClient: DependencyKey {
	public static let liveValue: Self = {
		let userDefaults = { @Sendable in UserDefaults(suiteName: "group.com.radixpublishing.preview")! }
		let removeValueForKey: RemoveValueForKey = { userDefaults().removeObject(forKey: $0.rawValue) }
		return Self(
			stringForKey: { userDefaults().string(forKey: $0.rawValue) },
			boolForKey: { userDefaults().bool(forKey: $0.rawValue) },
			dataForKey: { userDefaults().data(forKey: $0.rawValue) },
			doubleForKey: { userDefaults().double(forKey: $0.rawValue) },
			integerForKey: { userDefaults().integer(forKey: $0.rawValue) },
			remove: removeValueForKey,
			setString: { userDefaults().set($0, forKey: $1.rawValue) },
			setBool: { userDefaults().set($0, forKey: $1.rawValue) },
			setData: { userDefaults().set($0, forKey: $1.rawValue) },
			setDouble: { userDefaults().set($0, forKey: $1.rawValue) },
			setInteger: { userDefaults().set($0, forKey: $1.rawValue) },
			removeAll: {
				for key in Key.allCases {
					await removeValueForKey(key)
				}
			}
		)
	}()
}
