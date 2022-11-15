import Foundation

// MARK: - ManageGatewayAPIEndpoints.State
public extension ManageGatewayAPIEndpoints {
	struct State: Equatable {
		public var gatewayAPIURLString: String = ""
		public init() {}
	}
}

#if DEBUG
public extension ManageGatewayAPIEndpoints.State {
	static let placeholder: Self = .init()
}
#endif
