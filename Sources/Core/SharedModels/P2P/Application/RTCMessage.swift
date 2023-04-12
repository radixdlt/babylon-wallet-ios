import RadixConnectModels

// MARK: - P2P.RTCIncomingMessage
extension P2P {
	public struct RTCIncomingMessage: Sendable {
		public let connectionId: ConnectionPassword
		public let peerMessage: PeerConnectionMessage

		public struct PeerConnectionMessage: Sendable {
			public let peerConnectionId: PeerConnectionID
			public let result: Result<Content, Swift.Error>

			public enum Content: Sendable, Hashable, Decodable {
				struct WrongContentType: Swift.Error {}
				/// All Dapp interactions
				case dapp(P2P.FromDapp.WalletInteraction)

				/// e.g. for Ledger Nano interaction
				case connectorExtension(P2P.FromConnectorExtension)

				public var dapp: P2P.FromDapp.WalletInteraction? {
					guard case let .dapp(fromDapp) = self else { return nil }
					return fromDapp
				}

				public func asDapp() throws -> P2P.FromDapp.WalletInteraction {
					guard let dapp else {
						throw WrongContentType()
					}
					return dapp
				}

				public init(from decoder: Decoder) throws {
					do {
						self = try .dapp(.init(from: decoder))
					} catch let dappError {
						do {
							self = try .connectorExtension(.init(from: decoder))
						} catch {
							debugPrint("Unable to parse incoming RTC message, failed to parse as dapp and failed to parse as connectorExtension message. dapp decode error: \(dappError)")
							throw error
						}
					}
				}
			}

			public init(
				peerConnectionId: PeerConnectionID,
				result: Result<Content, Swift.Error>
			) {
				self.peerConnectionId = peerConnectionId
				self.result = result
			}
		}

		public init(
			connectionId: ConnectionPassword,
			peerMessage: PeerConnectionMessage
		) {
			self.connectionId = connectionId
			self.peerMessage = peerMessage
		}
	}
}

// MARK: - P2P.RTCOutgoingMessage
extension P2P {
	public struct RTCOutgoingMessage: Sendable, Hashable {
		public let connectionId: ConnectionPassword
		public let peerMessage: PeerConnectionMessage

		public struct PeerConnectionMessage: Sendable, Hashable {
			public let peerConnectionId: PeerConnectionID
			public let content: Content

			public enum Content: Sendable, Hashable, Encodable {
				/// All Dapp interactions
				case dapp(P2P.ToDapp.WalletInteractionResponse)

				/// e.g. for Ledger Nano interaction
				case connectorExtension(P2P.ToConnectorExtension)

				public var dapp: P2P.ToDapp.WalletInteractionResponse? {
					guard case let .dapp(toDapp) = self else { return nil }
					return toDapp
				}
			}

			public init(
				peerConnectionId: PeerConnectionID,
				content: Content
			) {
				self.peerConnectionId = peerConnectionId
				self.content = content
			}

			public static func toDapp(
				response: P2P.ToDapp.WalletInteractionResponse,
				peerConnectionId: PeerConnectionID
			) -> Self {
				.init(
					peerConnectionId: peerConnectionId,
					content: .dapp(response)
				)
			}
		}

		public init(
			connectionId: ConnectionPassword,
			content: PeerConnectionMessage
		) {
			self.connectionId = connectionId
			self.peerMessage = content
		}

		public static func toDapp(
			response: P2P.ToDapp.WalletInteractionResponse,
			peerConnectionId: PeerConnectionID, // is this calculated from ConnectionPassword
			connectionId: ConnectionPassword
		) -> Self {
			.init(
				connectionId: connectionId,
				content: .toDapp(response: response, peerConnectionId: peerConnectionId)
			)
		}
	}
}

extension P2P.RTCOutgoingMessage.PeerConnectionMessage.Content {
	public func encode(to encoder: Encoder) throws {
		switch self {
		case let .dapp(toDapp):
			try toDapp.encode(to: encoder)
		case .connectorExtension:
			fatalError("impl me")
		}
	}
}

//// MARK: - P2P.RTCIncomingMessage.PeerConnectionMessage + Hashable, Equatable
// extension P2P.RTCIncomingMessage.PeerConnectionMessage: Hashable, Equatable where PeerConnectionContent: Hashable & Equatable {}
//
//// MARK: - P2P.RTCIncomingMessage + Hashable, Equatable
// extension P2P.RTCIncomingMessage: Hashable, Equatable where PeerConnectionContent: Hashable & Equatable {}
