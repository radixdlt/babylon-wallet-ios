import Foundation
import Profile

// MARK: - P2P.RequestFromClient
public extension P2P {
	// MARK: - RequestFromClient
	struct RequestFromClient: Sendable, Hashable, Identifiable {
		public let requestFromDapp: FromDapp.Request
		public let client: P2PClient

		public init(
			requestFromDapp: FromDapp.Request,
			client: P2PClient
		) throws {
			self.requestFromDapp = requestFromDapp
			self.client = client
		}
	}
}

public extension P2P.RequestFromClient {
	typealias ID = P2P.FromDapp.Request.ID
	var id: ID {
		requestFromDapp.id
	}
}

// MARK: - InvalidRequestFromDapp
public struct InvalidRequestFromDapp: Swift.Error, Equatable, CustomStringConvertible {
	public let description: String
}

#if DEBUG
public extension P2PClient {
	static let placeholder: Self = try! .init(
		displayName: "Placeholder",
		connectionPassword: Data(hexString: "deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef")
	)
}

public extension P2P.RequestFromClient {
	static let placeholder: Self = try! .init(
		requestFromDapp: .placeholderOneTimeAccount,
		client: .placeholder
	)
}
#endif // DEBUG
