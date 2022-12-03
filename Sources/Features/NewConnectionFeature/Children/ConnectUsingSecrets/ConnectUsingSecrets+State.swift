import ConverseCommon
import Foundation

// MARK: - ConnectUsingSecrets.State
public extension ConnectUsingSecrets {
	struct State: Equatable {
		public var connectionSecrets: ConnectionSecrets
		public init(connectionSecrets: ConnectionSecrets) {
			self.connectionSecrets = connectionSecrets
		}
	}
}

#if DEBUG
public extension ConnectUsingSecrets.State {
	static let previewValue: Self = .init(connectionSecrets: .placeholder)
}
#endif
