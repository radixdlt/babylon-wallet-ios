import P2PModels
import Prelude
import ProfileModels

// MARK: - P2P.ResponseToClientByID
public extension P2P {
	// MARK: - ResponseToClientByID
	struct ResponseToClientByID: Sendable, Equatable {
		public let connectionID: P2PConnectionID
		public let responseToDapp: ToDapp.WalletInteractionResponse
		public init(
			connectionID: P2PConnectionID,
			responseToDapp: ToDapp.WalletInteractionResponse
		) {
			self.connectionID = connectionID
			self.responseToDapp = responseToDapp
		}
	}
}
