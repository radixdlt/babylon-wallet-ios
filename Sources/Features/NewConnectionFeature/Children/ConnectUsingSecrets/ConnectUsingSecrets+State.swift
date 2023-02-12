import FeaturePrelude
import P2PConnection

// MARK: - ConnectUsingSecrets.State
extension ConnectUsingSecrets {
	public struct State: Equatable {
		public var connectionSecrets: ConnectionSecrets
		public var isConnecting: Bool
		public var isPromptingForName: Bool
		public var nameOfConnection: String
		public var idOfNewConnection: P2PConnectionID?
		public var isNameValid: Bool
		@BindableState public var focusedField: Field?

		public init(
			connectionSecrets: ConnectionSecrets,
			isConnecting: Bool = true,
			idOfNewConnection: P2PConnectionID? = nil,
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
			self.idOfNewConnection = idOfNewConnection
			self.isNameValid = isNameValid
		}
	}
}

#if DEBUG
extension ConnectUsingSecrets.State {
	public static let previewValue: Self = .init(connectionSecrets: .placeholder)
}
#endif
