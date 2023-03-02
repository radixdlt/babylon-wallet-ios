import FeaturePrelude

// MARK: - ConnectUsingSecrets.State
extension ConnectUsingSecrets {
	public struct State: Equatable {
		public var connectionSecrets: ConnectionPassword
		public var isConnecting: Bool
		public var isPromptingForName: Bool
		public var nameOfConnection: String
		public var isNameValid: Bool
		@BindableState public var focusedField: Field?

		public init(
			connectionSecrets: ConnectionPassword,
			isConnecting: Bool = true,
			focusedField: Field? = nil,
			isPromptingForName: Bool = false,
			nameOfConnection: String = "",
			isNameValid: Bool = false
		) {
			self.focusedField = focusedField
			self.connectionSecrets = connectionSecrets
			self.isConnecting = isConnecting
			self.isPromptingForName = isPromptingForName
			self.nameOfConnection = nameOfConnection
			self.isNameValid = isNameValid
		}
	}
}

#if DEBUG
extension ConnectUsingSecrets.State {
	public static let previewValue: Self = .init(connectionSecrets: .placeholder)
}
#endif
