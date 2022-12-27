import ComposableArchitecture
import Foundation
import P2PConnection

// MARK: - ConnectUsingSecrets.State
public extension ConnectUsingSecrets {
	struct State: Equatable {
		public var connectionSecrets: ConnectionSecrets
		public var isConnecting: Bool
		public var isPromptingForName: Bool
		public var nameOfConnection: String
		public var newP2PConnection: P2PConnection?
		public var isNameValid: Bool
		@BindableState public var focusedField: Field?

		public init(
			connectionSecrets: ConnectionSecrets,
			isConnecting: Bool = true,
			newP2PConnection: P2PConnection? = nil,
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
			self.newP2PConnection = newP2PConnection
			self.isNameValid = isNameValid
		}
	}
}

#if DEBUG
public extension ConnectUsingSecrets.State {
	static let previewValue: Self = .init(connectionSecrets: .previewValue)
}
#endif
