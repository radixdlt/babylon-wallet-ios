import Foundation
import GatewayAPI
import Profile

// MARK: Settings.State
public extension Settings {
	// MARK: State
	struct State: Equatable {
		#if DEBUG
		public var profileToInspect: Profile?
		#endif // DEBUG

		/// Fetched from the RDX Ledger
		public var currentEpoch: EpochResponse?

		public init() {}
	}
}
