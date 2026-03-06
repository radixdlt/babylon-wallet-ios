// MARK: - ContactSupportClient
struct ContactSupportClient {
	/// Opens an external mail app with a preloaded subject, recipient and body that allows the user to contact support.
	var openEmail: OpenEmail

	/// Opens the public support channel in an external application.
	var openSupport: OpenSupport

	/// Returns whether email support is currently configured.
	var isEmailSupportAvailable: IsEmailSupportAvailable
}

// MARK: ContactSupportClient
extension ContactSupportClient {
	typealias OpenEmail = @Sendable (_ additionalBodyInfo: String?) async -> Void
	typealias OpenSupport = @Sendable () async -> Void
	typealias IsEmailSupportAvailable = @Sendable () -> Bool
}

extension DependencyValues {
	var contactSupportClient: ContactSupportClient {
		get { self[ContactSupportClient.self] }
		set { self[ContactSupportClient.self] = newValue }
	}
}
