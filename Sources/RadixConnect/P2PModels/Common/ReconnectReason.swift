import Foundation

public indirect enum ReconnectReason: Sendable, Hashable {
	case remoteClientJustConnectedToSignalingServer
	case lastReconnectAttemptFailed(reasonTriggerReconnectInTheFirstPlace: ReconnectReason)
}
