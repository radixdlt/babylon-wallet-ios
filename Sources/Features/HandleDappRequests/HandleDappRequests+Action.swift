import Collections
import ComposableArchitecture
import Foundation
import GrantDappWalletAccessFeature
import Peer
import Profile
import SharedModels
import TransactionSigningFeature

// MARK: - HandleDappRequests.Action
public extension HandleDappRequests {
	enum Action: Sendable, Equatable {
		public static func view(_ action: InternalAction.ViewAction) -> Self { .internal(.view(action)) }
		case `internal`(InternalAction)
		case child(ChildAction)
	}
}

public extension HandleDappRequests.Action {
	enum InternalAction: Sendable, Equatable {
		case system(SystemAction)
		case view(ViewAction)
	}

	enum ChildAction: Sendable, Equatable {
		case chooseAccounts(ChooseAccounts.Action)
		case transactionSigning(TransactionSigning.Action)
	}
}

public extension HandleDappRequests.Action.InternalAction {
	enum ViewAction: Sendable, Equatable {
		case task
	}

	enum SystemAction: Sendable, Equatable {
		case receivedRequestIsValidHandleIt(P2P.RequestFromClient)
		case loadConnections
		case sendMessageReceivedReceiptBackToPeer(P2PClient, msgID: Peer.MessageID)
		case sendMessageReceivedReceiptBackToPeerResult(TaskResult<Peer.MessageID>)
		case receiveRequestFromP2PClientResult(TaskResult<P2P.RequestFromClient>)
		case rejected(P2P.RequestFromClient)
		case failedWithError(P2P.RequestFromClient, P2P.ToDapp.Response.Failure.Kind.Error, String?)
		case handleNextRequestItemIfNeeded
		case presentViewForP2PRequest(P2P.RequestItemToHandle)
		case sendResponseBackToDappResult(TaskResult<P2P.SentResponseToClient>)
	}
}
