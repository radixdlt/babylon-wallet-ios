#if DEBUG
import Common
import CryptoKit
import Dependencies
import EngineToolkit
import Foundation
import enum SLIP10.PrivateKey
import enum SLIP10.PublicKey
import XCTestDynamicOverlay

struct MockedAlwaysFailingTX: Swift.Error {}
extension EngineToolkitClient: TestDependencyKey {}
public extension EngineToolkitClient {
	static let noop = Self(signTransactionIntent: { _ in
		throw MockedAlwaysFailingTX()
	})
	static let previewValue = Self.noop
	static let testValue = Self(
		signTransactionIntent: unimplemented("\(Self.self).signTransactionIntent is unimplemented")
	)
}

#endif
