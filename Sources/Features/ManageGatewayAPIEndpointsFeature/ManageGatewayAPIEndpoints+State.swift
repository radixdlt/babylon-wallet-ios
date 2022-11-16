import Foundation
import Profile

// MARK: - ManageGatewayAPIEndpoints.State
public extension ManageGatewayAPIEndpoints {
	struct State: Equatable {
		public var networkAndGateway: AppPreferences.NetworkAndGateway?
		public var gatewayAPIURLString: String
		public var isSwitchToButtonEnabled: Bool
		public init(
			networkAndGateway: AppPreferences.NetworkAndGateway? = nil,
			gatewayAPIURLString: String = "",
			isSwitchToButtonEnabled: Bool = false
		) {
			self.networkAndGateway = networkAndGateway
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
