#if DEBUG
import Foundation
import Profile
import XCTestDynamicOverlay

public extension ProfileClient {
	static let unimplemented: Self = .init(
		getCurrentNetworkID: XCTUnimplemented("\(Self.self).getCurrentNetworkID is unimplemented"),
		setCurrentNetworkID: XCTUnimplemented("\(Self.self).setCurrentNetworkID is unimplemented"),
		createNewProfile: XCTUnimplemented("\(Self.self).createNewProfile is unimplemented"),
		injectProfile: XCTUnimplemented("\(Self.self).injectProfile is unimplemented"),
		extractProfileSnapshot: XCTUnimplemented("\(Self.self).extractProfileSnapshot is unimplemented"),
		deleteProfileSnapshot: XCTUnimplemented("\(Self.self).deleteProfileSnapshot is unimplemented"),
		getAccounts: XCTUnimplemented("\(Self.self).getAccounts is unimplemented"),
		getBrowserExtensionConnections: XCTUnimplemented("\(Self.self).getBrowserExtensionConnections is unimplemented"),
		addBrowserExtensionConnection: XCTUnimplemented("\(Self.self).addBrowserExtensionConnection is unimplemented"),
		deleteBrowserExtensionConnection: XCTUnimplemented("\(Self.self).deleteBrowserExtensionConnection is unimplemented"),
		getAppPreferences: XCTUnimplemented("\(Self.self).getAppPreferences is unimplemented"),
		setDisplayAppPreferences: XCTUnimplemented("\(Self.self).setDisplayAppPreferences is unimplemented"),
		createAccount: XCTUnimplemented("\(Self.self).createAccount is unimplemented")
	)
}
#endif
