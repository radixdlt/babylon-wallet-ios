import SargonUniFFI

// MARK: - SecureSessionStorage
final class SecureSessionStorage: SessionStorage {
	@Dependency(\.secureStorageClient) var secureStorageClient

	func saveSession(sessionId: SessionId, encodedSession: Data) async throws {
		try secureStorageClient.saveRadixConnectMobileSession(sessionId, encodedSession)
	}

	func loadSession(sessionId: SessionId) async throws -> Data? {
		try secureStorageClient.loadRadixConnectMobileSession(sessionId)
	}
}
