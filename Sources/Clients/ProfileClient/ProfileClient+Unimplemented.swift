#if DEBUG
import Foundation
import Profile
import XCTestDynamicOverlay

public extension ProfileClient {
	static let unimplemented = Self(
		getCurrentNetworkID: XCTUnimplemented("\(Self.self).getCurrentNetworkID is unimplemented"),
		setCurrentNetworkID: XCTUnimplemented("\(Self.self).setCurrentNetworkID is unimplemented"),
		createNewProfile: XCTUnimplemented("\(Self.self).createNewProfile is unimplemented"),
		injectProfile: XCTUnimplemented("\(Self.self).injectProfile is unimplemented"),
		extractProfileSnapshot: XCTUnimplemented("\(Self.self).extractProfileSnapshot is unimplemented"),
		deleteProfileSnapshot: XCTUnimplemented("\(Self.self).deleteProfileSnapshot is unimplemented"),
		getAccounts: XCTUnimplemented("\(Self.self).getAccounts is unimplemented"),
		getAppPreferences: XCTUnimplemented("\(Self.self).getAppPreferences is unimplemented"),
		setDisplayAppPreferences: XCTUnimplemented("\(Self.self).setDisplayAppPreferences is unimplemented"),
		createAccount: XCTUnimplemented("\(Self.self).createAccount is unimplemented"),
		lookupAccountByAddress: XCTUnimplemented("\(Self.self).lookupAccountByAddress is unimplemented"),
		signTransaction: XCTUnimplemented("\(Self.self).lookupAccountByAddress is unimplemented")
	)
}
#endif
