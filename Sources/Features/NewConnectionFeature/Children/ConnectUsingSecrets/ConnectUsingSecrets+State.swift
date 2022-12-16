import ComposableArchitecture
import Foundation
import Peer

// MARK: - ConnectUsingSecrets.State
public extension ConnectUsingSecrets {
	struct State: Equatable {
		public var connectionSecrets: ConnectionSecrets
		public var isConnecting: Bool
		public var isPromptingForName: Bool
		public var nameOfConnection: String
		public var newPeer: Peer?
		public var isNameValid: Bool
		@BindableState public var focusedField: Field?

		public init(
			connectionSecrets: ConnectionSecrets,
			isConnecting: Bool = true,
			connectedPeer: Peer? = nil,
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
			self.newPeer = connectedPeer
			self.isNameValid = isNameValid
		}
	}
}

#if DEBUG
public extension ConnectUsingSecrets.State {
	static let previewValue: Self = .init(connectionSecrets: .placeholder)
}
#endif
