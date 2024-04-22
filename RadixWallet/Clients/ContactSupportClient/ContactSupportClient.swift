// MARK: - ContactSupportClient
struct ContactSupportClient: Sendable {
	/// Opens an external mail app with a preloaded subject, recipient and body that allows the user to contact support.
	///
	/// The external mail application will be the first one available from the following list:
	/// - Gmail
	/// - Outlook
	/// - Apple Mail
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
