import Common
import CryptoKit
import Dependencies
import EngineToolkit
import Foundation
import enum SLIP10.PrivateKey
import enum SLIP10.PublicKey
import XCTestDynamicOverlay

extension EngineToolkitClient: TestDependencyKey {
	public static let previewValue = Self(
		getTransactionVersion: { Version.default },
		signTransactionIntent: { _ in
			struct MockedAlwaysFailingTX: Swift.Error {}
			throw MockedAlwaysFailingTX()
		},
		accountAddressesNeedingToSignTransaction: { _, _, _ in [] }
	)
	public static let testValue = Self(
		getTransactionVersion: unimplemented("\(Self.self).getTransactionVersion"),
		signTransactionIntent: unimplemented("\(Self.self).signTransactionIntent"),
		accountAddressesNeedingToSignTransaction: unimplemented("\(Self.self).accountAddressesNeedingToSignTransaction")
	)
}
