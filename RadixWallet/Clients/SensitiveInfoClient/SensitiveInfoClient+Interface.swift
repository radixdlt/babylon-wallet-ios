// MARK: - SensitiveInfoClient
struct SensitiveInfoClient: Sendable {
	var read: Read
}

// MARK: SensitiveInfoClient.Read
extension SensitiveInfoClient {
	typealias Read = @Sendable (_ key: Key) -> String?
}

extension DependencyValues {
	var sensitiveInfoClient: SensitiveInfoClient {
		get { self[SensitiveInfoClient.self] }
		set { self[SensitiveInfoClient.self] = newValue }
	}
}

// MARK: - SensitiveInfoClient.Key
extension SensitiveInfoClient {
	struct Key: RawRepresentable, Hashable, Sendable {
		let rawValue: String

		init(rawValue: String) {
			self.rawValue = rawValue
		}
	}
}
