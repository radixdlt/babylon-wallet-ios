import CreateEntityFeature
import FeaturePrelude

// MARK: - ManageGatewayAPIEndpoints.State
extension ManageGatewayAPIEndpoints {
	public struct State: Sendable, Hashable {
		@PresentationState
		public var destination: Destinations.State?

		public var urlString: String
		public var currentGateway: Gateway?
		public var isValidatingEndpoint: Bool
		public var isSwitchToButtonEnabled: Bool

		public var validatedNewGatewayToSwitchTo: Gateway?
		@BindingState public var focusedField: Field?

		public init(
			urlString: String = "",
			currentGateway: Gateway? = nil,
			validatedNewGatewayToSwitchTo: Gateway? = nil,
			isSwitchToButtonEnabled: Bool = false,
			isValidatingEndpoint: Bool = false
		) {
			self.urlString = urlString
			self.currentGateway = currentGateway
			self.validatedNewGatewayToSwitchTo = validatedNewGatewayToSwitchTo
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
