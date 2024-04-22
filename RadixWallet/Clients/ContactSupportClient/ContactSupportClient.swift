// MARK: - ContactSupportClient
struct ContactSupportClient: Sendable {
	var openEmail: OpenEmail
}

// MARK: ContactSupportClient.OpenEmail
extension ContactSupportClient {
	typealias OpenEmail = @Sendable () async -> Void
}

extension DependencyValues {
	var contactSupportClient: ContactSupportClient {
		get { self[ContactSupportClient.self] }
		set { self[ContactSupportClient.self] = newValue }
	}
}
