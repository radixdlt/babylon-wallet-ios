import ComposableArchitecture
import SwiftUI

// MARK: - NewConnection
public struct NewConnection: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public enum Root: Sendable, Hashable {
			case localNetworkPermission(LocalNetworkPermission.State)
			case scanQR(ScanQRCoordinator.State)
			case nameConnection(NewConnectionName.State)
		}

		public var root: Root

		public var linkConnectionQRData: LinkConnectionQRData?

		public var connectionName: String?

		public init() {
			self.root = .localNetworkPermission(.init())
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case closeButtonTapped
	}

	public enum ChildAction: Sendable, Equatable {
		case localNetworkPermission(LocalNetworkPermission.Action)
		case scanQR(ScanQRCoordinator.Action)
		case nameConnection(NewConnectionName.Action)
	}

	public enum DelegateAction: Sendable, Equatable {
		case dismiss
		case newConnection(P2PLink)
	}

	public enum InternalAction: Sendable, Equatable {
		case linkConnectionDataFromStringResult(TaskResult<LinkConnectionQRData>)
		case establishConnection(String)
		case establishConnectionResult(TaskResult<LinkConnectionQRData>)

		case connectionName
	}

	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.p2pLinksClient) var p2pLinksClient
	@Dependency(\.jsonDecoder) var jsonDecoder
	@Dependency(\.radixConnectClient) var radixConnectClient

	public init() {}

	public var body: some ReducerOf<Self> {
		Scope(state: \.root, action: /Action.child) {
			EmptyReducer()
				.ifCaseLet(/State.Root.localNetworkPermission, action: /ChildAction.localNetworkPermission) {
					LocalNetworkPermission()
				}
				.ifCaseLet(/State.Root.scanQR, action: /ChildAction.scanQR) {
					ScanQRCoordinator()
				}
				.ifCaseLet(/State.Root.nameConnection, action: /ChildAction.nameConnection) {
					NewConnectionName()
				}
		}

		Reduce(core)
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .closeButtonTapped:
			.send(.delegate(.dismiss))
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .linkConnectionDataFromStringResult(.success(data)):
			state.linkConnectionQRData = data

			return .run { send in
				switch data.purpose {
				case .general:
					let p2pLinks = await p2pLinksClient.getP2PLinks()

					if let p2pLink = p2pLinks.first(where: { $0.publicKey == data.publicKey }) {
						if p2pLink.purpose == data.purpose {
							// [NewConnectionApproval] This appears to be a Radix Connector you previously linked to. Link will be updated.
							await send(.internal(.establishConnection(p2pLink.displayName)))
						} else {
							// Inform users that changing purposes is not supported
							// - Changing a Connector’s type is not supported.
						}
					} else {
						// [NewConnectionApproval] Is this the official Radix Connect browser extension, or a Connector you trust to relay requests from many dApps?”
						await send(.internal(.connectionName))
					}
				case .dAppSpecific:
					// Inform users that dApp specific linkage is not supported
					break
				}
			}
		case let .linkConnectionDataFromStringResult(.failure(error)):
			errorQueue.schedule(error)
			return .none

		case let .establishConnection(connectionName):
			guard let linkConnectionQRData = state.linkConnectionQRData else { return .none }

			state.connectionName = connectionName

			switch state.root {
			case var .nameConnection(nameState):
				nameState.isConnecting = true
				state.root = .nameConnection(nameState)
			default:
				break
			}

			return .run { send in
				await send(.internal(.establishConnectionResult(
					TaskResult {
						try await radixConnectClient.addP2PWithPassword(linkConnectionQRData.password)
						return linkConnectionQRData
					}
				)))
			}

		case let .establishConnectionResult(.success(linkConnectionQRData)):
			guard let connectionName = state.connectionName else { return .none }

			let p2pLink = P2PLink(
				connectionPassword: linkConnectionQRData.password,
				publicKey: linkConnectionQRData.publicKey,
				purpose: linkConnectionQRData.purpose,
				displayName: connectionName
			)
			return .run { send in
				let p2pLinks = await p2pLinksClient.getP2PLinks()

				if let oldP2PLink = p2pLinks.first(where: { $0.publicKey == linkConnectionQRData.publicKey }) {
					try await radixConnectClient.deleteP2PLinkByPassword(oldP2PLink.connectionPassword)
				}

				await send(.delegate(.newConnection(p2pLink)))
			}

		case let .establishConnectionResult(.failure(error)):
			errorQueue.schedule(error)

			switch state.root {
			case var .nameConnection(nameState):
				nameState.isConnecting = false
				state.root = .nameConnection(nameState)
			default:
				break
			}

			return .none

		case .connectionName:
			state.root = .nameConnection(.init())
			return .none
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case let .localNetworkPermission(.delegate(.permissionResponse(allowed))):
			if allowed {
				let string = L10n.LinkedConnectors.NewConnection.subtitle
				state.root = .scanQR(.init(scanInstructions: string))
				return .none
			} else {
				return .send(.delegate(.dismiss))
			}

		case let .scanQR(.delegate(.scanned(qrString))):
			return .run { send in
				let result = await TaskResult {
					try jsonDecoder().decode(LinkConnectionQRData.self, from: Data(qrString.utf8))
				}
				await send(.internal(.linkConnectionDataFromStringResult(result)))
			}

		case let .nameConnection(.delegate(.nameSet(connectionName))):
			return .send(.internal(.establishConnection(connectionName)))

		default:
			return .none
		}
	}
}
