import Foundation

// MARK: - PersonaConnectionRequest.State
public extension PersonaConnectionRequest {
	struct State: Equatable {
		public let dApp: dApp

		public init(
			dApp: dApp
		) {
			self.dApp = dApp
		}
	}
}

#if DEBUG
public extension PersonaConnectionRequest.State {
	static let placeholder: Self = .init(
		dApp: .placeholder
	)
}
#endif
