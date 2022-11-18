import Foundation
import Profile
import URLBuilderClient

// MARK: - ManageGatewayAPIEndpoints.State
public extension ManageGatewayAPIEndpoints {
	struct State: Equatable {
		public var networkAndGateway: AppPreferences.NetworkAndGateway?

		public var host: URLInput.Host?
		public var port: URLInput.Port?
		public var path: URLInput.Path
		public var scheme: URLInput.Scheme
		public var url: URL?
		public var isSwitchToButtonEnabled: Bool

		public init(
			networkAndGateway: AppPreferences.NetworkAndGateway? = nil,
			host: URLInput.Host? = nil,
			port: URLInput.Port? = nil,
			path: URLInput.Path = "",
			scheme: URLInput.Scheme = "https",
			url: URL? = nil,
			isSwitchToButtonEnabled: Bool = false
		) {
			self.networkAndGateway = networkAndGateway
			self.host = host
			self.port = port
			self.path = path
			self.scheme = scheme
			self.url = url
			self.isSwitchToButtonEnabled = isSwitchToButtonEnabled
		}
	}
}

#if DEBUG
public extension ManageGatewayAPIEndpoints.State {
	static let placeholder: Self = .init()
}
#endif
