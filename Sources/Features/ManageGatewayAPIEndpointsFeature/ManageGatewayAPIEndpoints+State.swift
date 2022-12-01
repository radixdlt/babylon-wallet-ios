import CreateAccountFeature
import Foundation
import Profile

// MARK: - ManageGatewayAPIEndpoints.State
public extension ManageGatewayAPIEndpoints {
	struct State: Equatable {
		public var createAccount: CreateAccount.State?

		public var urlString: String
		public var currentNetworkAndGateway: AppPreferences.NetworkAndGateway?
		public var isValidatingEndpoint: Bool
		public var isSwitchToButtonEnabled: Bool

		public var validatedNewNetworkAndGatewayToSwitchTo: AppPreferences.NetworkAndGateway?

		public init(
			createAccount: CreateAccount.State? = nil,
			urlString: String = "",
			currentNetworkAndGateway: AppPreferences.NetworkAndGateway? = nil,
			validatedNewNetworkAndGatewayToSwitchTo: AppPreferences.NetworkAndGateway? = nil,
			isSwitchToButtonEnabled: Bool = false,
			isValidatingEndpoint: Bool = false
		) {
			self.createAccount = createAccount
			self.urlString = urlString
			self.currentNetworkAndGateway = currentNetworkAndGateway
			self.validatedNewNetworkAndGatewayToSwitchTo = validatedNewNetworkAndGatewayToSwitchTo
			self.isSwitchToButtonEnabled = isSwitchToButtonEnabled
			self.isValidatingEndpoint = isValidatingEndpoint
		}
	}
}

#if DEBUG
public extension ManageGatewayAPIEndpoints.State {
	static let placeholder: Self = .init()
}
#endif
