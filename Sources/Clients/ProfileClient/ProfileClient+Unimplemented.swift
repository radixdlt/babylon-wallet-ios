#if DEBUG
import Foundation
import Profile
import XCTestDynamicOverlay

public extension ProfileClient {
	static let testValue = Self(
		getCurrentNetworkID: unimplemented("\(Self.self).getCurrentNetworkID"),
		setCurrentNetworkID: unimplemented("\(Self.self).setCurrentNetworkID"),
		createNewProfile: unimplemented("\(Self.self).createNewProfile"),
		injectProfile: unimplemented("\(Self.self).injectProfile"),
		extractProfileSnapshot: unimplemented("\(Self.self).extractProfileSnapshot"),
		deleteProfileSnapshot: unimplemented("\(Self.self).deleteProfileSnapshot"),
		getAccounts: unimplemented("\(Self.self).getAccounts"),
		getBrowserExtensionConnections: unimplemented("\(Self.self).getBrowserExtensionConnections"),
		addBrowserExtensionConnection: unimplemented("\(Self.self).addBrowserExtensionConnection"),
		deleteBrowserExtensionConnection: unimplemented("\(Self.self).deleteBrowserExtensionConnection"),
		getAppPreferences: unimplemented("\(Self.self).getAppPreferences"),
		setDisplayAppPreferences: unimplemented("\(Self.self).setDisplayAppPreferences"),
		createAccount: unimplemented("\(Self.self).createAccount"),
		lookupAccountByAddress: unimplemented("\(Self.self).lookupAccountByAddress"),
		signTransaction: unimplemented("\(Self.self).signTransaction")
	)
}
#endif
