import Foundation
import Prelude

// MARK: - UserDefaultsClient + DependencyKey
extension UserDefaultsClient: DependencyKey {
	public static let liveValue: Self = {
		let userDefaults = { @Sendable in UserDefaults(suiteName: "group.com.radixpublishing.preview")! }
		return Self(
			stringForKey: { userDefaults().string(forKey: $0) },
			boolForKey: { userDefaults().bool(forKey: $0) },
			dataForKey: { userDefaults().data(forKey: $0) },
			doubleForKey: { userDefaults().double(forKey: $0) },
			integerForKey: { userDefaults().integer(forKey: $0) },
			remove: { userDefaults().removeObject(forKey: $0) },
			setString: { userDefaults().set($0, forKey: $1) },
			setBool: { userDefaults().set($0, forKey: $1) },
			setData: { userDefaults().set($0, forKey: $1) },
			setDouble: { userDefaults().set($0, forKey: $1) },
			setInteger: { userDefaults().set($0, forKey: $1) }
		)
	}()
}
