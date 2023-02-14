import CreateEntityFeature
import FeaturePrelude

// MARK: - ManageGatewayAPIEndpoints.State
extension ManageGatewayAPIEndpoints {
	public struct State: Equatable {
		public var createAccountCoordinator: CreateAccountCoordinator.State?

		public var urlString: String
		public var currentNetworkAndGateway: AppPreferences.NetworkAndGateway?
		public var isValidatingEndpoint: Bool
		public var isSwitchToButtonEnabled: Bool

		public var validatedNewNetworkAndGatewayToSwitchTo: AppPreferences.NetworkAndGateway?
		@BindableState public var focusedField: Field?

		public init(
			createAccountCoordinator: CreateAccountCoordinator.State? = nil,
			urlString: String = "",
			currentNetworkAndGateway: AppPreferences.NetworkAndGateway? = nil,
			validatedNewNetworkAndGatewayToSwitchTo: AppPreferences.NetworkAndGateway? = nil,
			isSwitchToButtonEnabled: Bool = false,
			isValidatingEndpoint: Bool = false
		) {
			self.createAccountCoordinator = createAccountCoordinator
			self.urlString = urlString
			self.currentNetworkAndGateway = currentNetworkAndGateway
			self.validatedNewNetworkAndGatewayToSwitchTo = validatedNewNetworkAndGatewayToSwitchTo
			self.isSwitchToButtonEnabled = isSwitchToButtonEnabled
			self.isValidatingEndpoint = isValidatingEndpoint
		}
	}
}

// MARK: - ManageGatewayAPIEndpoints.State.Field
extension ManageGatewayAPIEndpoints.State {
	public enum Field: String, Sendable, Hashable {
		case gatewayURL
	}
}

extension ManageGatewayAPIEndpoints.State {
	var controlState: ControlState {
		if isValidatingEndpoint {
			return .loading(.local)
		} else if isSwitchToButtonEnabled {
			return .enabled
		} else {
			return .disabled
		}
	}
}

#if DEBUG
extension ManageGatewayAPIEndpoints.State {
	public static let previewValue: Self = .init()
}
#endif
