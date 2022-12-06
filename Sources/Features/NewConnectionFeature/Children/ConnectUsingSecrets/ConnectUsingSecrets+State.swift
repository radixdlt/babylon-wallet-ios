import ComposableArchitecture
import Converse
import ConverseCommon
import Foundation

// MARK: - ConnectUsingSecrets.State
public extension ConnectUsingSecrets {
	struct State: Equatable {
		public var connectionSecrets: ConnectionSecrets
		public var isConnecting: Bool
		public var isPromptingForName: Bool
		public var nameOfConnection: String
		public var connectedConnection: Connection?
		@BindableState public var focusedField: Field?
		public init(
			connectionSecrets: ConnectionSecrets,
			isConnecting: Bool = true,
			connectedConnection: Connection? = nil,
			focusedField: Field? = nil,
			isPromptingForName: Bool = false,
			nameOfConnection: String = ""
		) {
			self.focusedField = focusedField
			self.connectionSecrets = connectionSecrets
			self.isConnecting = isConnecting
			self.isPromptingForName = isPromptingForName
			self.nameOfConnection = nameOfConnection
			self.connectedConnection = connectedConnection
		}
	}
}

#if DEBUG
public extension ConnectUsingSecrets.State {
	static let previewValue: Self = .init(connectionSecrets: .placeholder)
}
#endif
