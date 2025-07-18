import ComposableArchitecture
import SwiftUI

// MARK: - NewConnection
struct NewConnection: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		typealias ConnectionName = String

		var root: Root.State

		@PresentationState
		var destination: Destination.State?

		var linkConnectionQRData: LinkConnectionQRData?
		var connectionName: ConnectionName?

		init(
			root: Root.State = .init(),
			linkConnectionQRData: LinkConnectionQRData? = nil,
			connectionName: ConnectionName? = nil
		) {
			self.root = root
			self.linkConnectionQRData = linkConnectionQRData
			self.connectionName = connectionName
		}
	}

	enum ViewAction: Sendable, Equatable {
		case closeButtonTapped
		case ledgerConnectionIntroContinueTapped
	}

	enum ChildAction: Sendable, Equatable {
		case root(Root.Action)
	}

	enum DelegateAction: Sendable, Equatable {
		case newConnection(P2PLink)
	}

	enum InternalAction: Sendable, Equatable {
		case linkConnectionDataFromStringResult(TaskResult<LinkConnectionQRData>)
		case establishConnection(String)
		case establishConnectionResult(TaskResult<P2PLink>)
		case approveConnection(NewConnectionApproval.State.Purpose)
		case showErrorAlert(AlertState<Destination.Action.ErrorAlert>)
	}

	struct Root: Sendable, Hashable, Reducer {
		@CasePathable
		enum State: Sendable, Hashable {
			case ledgerConnectionIntro
			case localNetworkPermission(LocalNetworkPermission.State)
			case scanQR(ScanQRCoordinator.State)
			case nameConnection(NewConnectionName.State)
			case connectionApproval(NewConnectionApproval.State)

			init() {
				self = .localNetworkPermission(.init())
			}
		}

		@CasePathable
		enum Action: Sendable, Equatable {
			case ledgerConnectionIntro(Never)
			case localNetworkPermission(LocalNetworkPermission.Action)
			case scanQR(ScanQRCoordinator.Action)
			case nameConnection(NewConnectionName.Action)
			case connectionApproval(NewConnectionApproval.Action)
		}

		var body: some ReducerOf<Self> {
			Scope(state: /State.localNetworkPermission, action: /Action.localNetworkPermission) {
				LocalNetworkPermission()
			}
			Scope(state: /State.scanQR, action: /Action.scanQR) {
				ScanQRCoordinator()
			}
			Scope(state: /State.connectionApproval, action: /Action.connectionApproval) {
				NewConnectionApproval()
			}
			Scope(state: /State.nameConnection, action: /Action.nameConnection) {
				NewConnectionName()
			}
		}
	}

	struct Destination: DestinationReducer {
		@CasePathable
		enum State: Sendable, Hashable {
			case errorAlert(AlertState<Action.ErrorAlert>)
		}

		@CasePathable
		enum Action: Sendable, Equatable {
			case errorAlert(ErrorAlert)

			enum ErrorAlert: Hashable, Sendable {
				case dismissTapped
			}
		}

		var body: some ReducerOf<Self> {
			EmptyReducer()
		}
	}

	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.p2pLinksClient) var p2pLinksClient
	@Dependency(\.jsonDecoder) var jsonDecoder
	@Dependency(\.radixConnectClient) var radixConnectClient
	@Dependency(\.dismiss) var dismiss
	@Dependency(\.continuousClock) var continuousClock

	init() {}

	var body: some ReducerOf<Self> {
		Scope(state: \.root, action: /Action.child .. ChildAction.root) {
			Root()
		}
		Reduce(core)
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .closeButtonTapped:
			return .run { _ in
				await dismiss()
			}
		case .ledgerConnectionIntroContinueTapped:
			state.root = .localNetworkPermission(.init())
			return .none
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .linkConnectionDataFromStringResult(.success(linkConnectionQRData)):
			state.linkConnectionQRData = linkConnectionQRData

			return .run { send in
				guard linkConnectionQRData.hasValidSignature() else {
					await send(.internal(.showErrorAlert(.invalidQRCode)))
					return
				}

				let p2pLinks = await p2pLinksClient.getP2PLinks()

				if let p2pLink = p2pLinks.first(where: { $0.publicKey == linkConnectionQRData.publicKeyOfOtherParty }) {
					if p2pLink.connectionPurpose == linkConnectionQRData.purpose {
						await send(.internal(.approveConnection(.approveExisitingConnection(p2pLink.displayName))))
					} else {
						await send(.internal(.showErrorAlert(.changingPurposeNotSupported)))
					}
				} else {
					switch linkConnectionQRData.purpose {
					case .general:
						await send(.internal(.approveConnection(.approveNewConnection)))
					case .unknown:
						await send(.internal(.showErrorAlert(.unknownPurpose)))
					}
				}
			}

		case let .linkConnectionDataFromStringResult(.failure(error)):
			errorQueue.schedule(error)
			return .none

		case let .establishConnection(connectionName):
			guard let linkConnectionQRData = state.linkConnectionQRData else { return .none }

			state.connectionName = connectionName
			updateConnectingState(for: &state, isConnecting: true)

			let p2pLink = P2PLink(
				connectionPassword: linkConnectionQRData.password,
				connectionPurpose: linkConnectionQRData.purpose,
				publicKey: linkConnectionQRData.publicKeyOfOtherParty,
				displayName: connectionName
			)

			return .run { send in
				await send(.internal(.establishConnectionResult(
					TaskResult {
						try await radixConnectClient.connectP2PLink(p2pLink)
						try await radixConnectClient.updateOrAddP2PLink(p2pLink)
						try await continuousClock.sleep(for: .seconds(1))
						return p2pLink
					}
				)))
			}

		case let .establishConnectionResult(.success(p2pLink)):
			updateConnectingState(for: &state, isConnecting: false)
			return .send(.delegate(.newConnection(p2pLink)))

		case let .establishConnectionResult(.failure(error)):
			errorQueue.schedule(error)
			updateConnectingState(for: &state, isConnecting: false)
			return .none

		case let .approveConnection(purpose):
			state.root = .connectionApproval(.init(purpose: purpose))
			return .none

		case let .showErrorAlert(error):
			state.destination = .errorAlert(error)
			return .none
		}
	}

	func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case let .root(.localNetworkPermission(.delegate(.permissionResponse(allowed)))):
			if allowed {
				state.root = .scanQR(.init(kind: .connectorExtension))
				return .none
			} else {
				return .run { _ in
					await dismiss()
				}
			}

		case let .root(.scanQR(.delegate(.scanned(qrString)))):
			return .run { send in
				if let _ = try? Exactly32Bytes(hex: qrString) {
					/// User scanned an old format QR code
					await send(.internal(.showErrorAlert(.oldFormatQRCode)))
					return
				}

				let result = await TaskResult {
					try jsonDecoder().decode(LinkConnectionQRData.self, from: Data(qrString.utf8))
				}
				await send(.internal(.linkConnectionDataFromStringResult(result)))
			}

		case let .root(.connectionApproval(.delegate(.approved(purpose)))):
			switch purpose {
			case .approveNewConnection:
				state.root = .nameConnection(.init())
				return .none
			case let .approveExisitingConnection(connectionName):
				return .send(.internal(.establishConnection(connectionName)))
			case .approveRelinkAfterProfileRestore, .approveRelinkAfterUpdate:
				state.root = .scanQR(.init(kind: .connectorExtension))
				return .none
			}

		case let .root(.nameConnection(.delegate(.nameSet(connectionName)))):
			return .send(.internal(.establishConnection(connectionName)))

		default:
			return .none
		}
	}

	func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case .errorAlert(.dismissTapped):
			.run { _ in
				await dismiss()
			}
		}
	}

	private func updateConnectingState(for state: inout State, isConnecting: Bool) {
		switch state.root {
		case var .connectionApproval(approvalState):
			approvalState.isConnecting = isConnecting
			state.root = .connectionApproval(approvalState)

		case var .nameConnection(nameState):
			nameState.isConnecting = isConnecting
			state.root = .nameConnection(nameState)

		default:
			break
		}
	}
}

extension AlertState<NewConnection.Destination.Action.ErrorAlert> {
	static var unknownPurpose: AlertState {
		AlertState {
			TextState(L10n.LinkedConnectors.linkFailedErrorTitle)
		} actions: {
			ButtonState(role: .cancel, action: .dismissTapped) {
				TextState(L10n.Common.dismiss)
			}
		} message: {
			TextState(L10n.LinkedConnectors.unknownPurposeErrorMessage)
		}
	}

	static var changingPurposeNotSupported: AlertState {
		AlertState {
			TextState(L10n.LinkedConnectors.linkFailedErrorTitle)
		} actions: {
			ButtonState(role: .cancel, action: .dismissTapped) {
				TextState(L10n.Common.dismiss)
			}
		} message: {
			TextState(L10n.LinkedConnectors.changingPurposeNotSupportedErrorMessage)
		}
	}

	static var invalidQRCode: AlertState {
		AlertState {
			TextState(L10n.LinkedConnectors.incorrectQrTitle)
		} actions: {
			ButtonState(role: .cancel, action: .dismissTapped) {
				TextState(L10n.Common.dismiss)
			}
		} message: {
			TextState(L10n.LinkedConnectors.incorrectQrMessage)
		}
	}

	static var oldFormatQRCode: AlertState {
		AlertState {
			TextState(L10n.LinkedConnectors.incorrectQrTitle)
		} actions: {
			ButtonState(role: .cancel, action: .dismissTapped) {
				TextState(L10n.Common.dismiss)
			}
		} message: {
			TextState(L10n.LinkedConnectors.oldQRErrorMessage)
		}
	}
}
