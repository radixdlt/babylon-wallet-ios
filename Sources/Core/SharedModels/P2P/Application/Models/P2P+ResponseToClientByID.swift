import P2PModels
import Prelude
import Profile

// MARK: - P2P.ResponseToClientByID
public extension P2P {
	// MARK: - ResponseToClientByID
	struct ResponseToClientByID: Sendable, Equatable, Identifiable {
		public let connectionID: P2PConnectionID
		public let responseToDapp: ToDapp.Response
		public init(
			connectionID: P2PConnectionID,
			responseToDapp: ToDapp.Response
		) {
			self.connectionID = connectionID
			self.responseToDapp = responseToDapp
		}
	}
}

public extension P2P.ResponseToClientByID {
	var requestID: P2P.ToDapp.Response.ID {
		responseToDapp.id
	}

	typealias ID = P2P.ToDapp.Response.ID
	var id: P2P.ToDapp.Response.ID { requestID }
}
