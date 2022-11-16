import Foundation

// MARK: - ManageGatewayAPIEndpoints.State
public extension ManageGatewayAPIEndpoints {
	struct State: Equatable {
		public var gatewayAPIURLString: String
		public var isSwitchToButtonEnabled: Bool
		public init(
			gatewayAPIURLString: String = "",
			isSwitchToButtonEnabled: Bool = false
		) {
			self.gatewayAPIURLString = gatewayAPIURLString
			self.isSwitchToButtonEnabled = isSwitchToButtonEnabled
		}
	}
}

#if DEBUG
public extension ManageGatewayAPIEndpoints.State {
	static let placeholder: Self = .init()
}
#endif
