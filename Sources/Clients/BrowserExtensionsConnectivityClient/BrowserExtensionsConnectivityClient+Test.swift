import AsyncExtensions
import Dependencies
import XCTestDynamicOverlay

// MARK: - BrowserExtensionsConnectivityClient + TestDependencyKey
extension BrowserExtensionsConnectivityClient: TestDependencyKey {
	public static let previewValue = Self.noop
	public static let testValue = Self(
		getBrowserExtensionConnections: unimplemented("\(Self.self).getBrowserExtensionConnections"),
		addBrowserExtensionConnection: unimplemented("\(Self.self).addBrowserExtensionConnection"),
		deleteBrowserExtensionConnection: unimplemented("\(Self.self).deleteBrowserExtensionConnection"),
		getConnectionStatusAsyncSequence: unimplemented("\(Self.self).getConnectionStatusAsyncSequence"),
		getIncomingMessageAsyncSequence: unimplemented("\(Self.self).getIncomingMessageAsyncSequence"),
		sendMessage: unimplemented("\(Self.self).sendMessage"),
		_sendTestMessage: unimplemented("\(Self.self)._sendTestMessage")
	)
}

extension BrowserExtensionsConnectivityClient {
	static let noop = Self(
		getBrowserExtensionConnections: { [] },
		addBrowserExtensionConnection: { _ in },
		deleteBrowserExtensionConnection: { _ in },
		getConnectionStatusAsyncSequence: { _ in AsyncLazySequence([]).eraseToAnyAsyncSequence() },
		getIncomingMessageAsyncSequence: { _ in AsyncLazySequence([]).eraseToAnyAsyncSequence() },
		sendMessage: { _ in fatalError() },
		_sendTestMessage: { _, _ in fatalError() }
	)
}

public extension DependencyValues {
	var browserExtensionsConnectivityClient: BrowserExtensionsConnectivityClient {
		get { self[BrowserExtensionsConnectivityClient.self] }
		set { self[BrowserExtensionsConnectivityClient.self] = newValue }
	}
}
