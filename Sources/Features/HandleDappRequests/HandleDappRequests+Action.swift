import Collections
import ComposableArchitecture
import Foundation
import GrantDappWalletAccessFeature
import Profile
import SharedModels
import TransactionSigningFeature

// MARK: - HandleDappRequests.Action
public extension HandleDappRequests {
	enum Action: Equatable {
		public static func view(_ action: InternalAction.ViewAction) -> Self { .internal(.view(action)) }
		case `internal`(InternalAction)
		case child(ChildAction)
	}
}

public extension HandleDappRequests.Action {
	enum InternalAction: Equatable {
		case system(SystemAction)
		case view(ViewAction)
	}

	enum ChildAction: Equatable {
		case grantDappWalletAccess(DappConnectionRequest.Action)
		case transactionSigning(TransactionSigning.Action)
	}
}

public extension HandleDappRequests.Action.InternalAction {
	enum ViewAction: Equatable {
		case task
	}

	enum SystemAction: Equatable {
		case loadConnections
		//        case connectionsLoadedResult(TaskResult<[P2P.ClientWithConnectionStatus]>)
		//        case subscribeToRequestsFromP2PClientByID(OrderedSet<P2PClient.ID>)
		case receiveRequestFromP2PClientResult(TaskResult<P2P.RequestFromClient>)
		case dismissed(P2P.RequestFromClient)
		case handleNextRequestItemIfNeeded
		case presentViewForP2PRequest(P2P.RequestItemToHandle)
		case sendResponseBackToDappResult(TaskResult<P2P.SentResponseToClient>)
	}
}
