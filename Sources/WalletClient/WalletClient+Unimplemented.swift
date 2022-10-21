//
//  File.swift
//
//
//  Created by Alexander Cyon on 2022-10-20.
//

#if DEBUG
import Foundation
import Profile
import XCTestDynamicOverlay

public extension WalletClient {
	static let unimplemented: Self = .init(
		injectProfile: XCTUnimplemented("\(Self.self).injectProfile is unimplemented"),
		extractProfileSnapshot: XCTUnimplemented("\(Self.self).extractProfileSnapshot is unimplemented"),
		deleteProfileSnapshot: XCTUnimplemented("\(Self.self).deleteProfileSnapshot is unimplemented"),
		getAccounts: XCTUnimplemented("\(Self.self).getAccounts is unimplemented"),
		getAppPreferences: XCTUnimplemented("\(Self.self).getAppPreferences is unimplemented"),
		setDisplayAppPreferences: XCTUnimplemented("\(Self.self).setDisplayAppPreferences is unimplemented"),
		createAccountWithKeychainClient: XCTUnimplemented("\(Self.self).createAccountWithKeychainClient is unimplemented")
	)
}
#endif
