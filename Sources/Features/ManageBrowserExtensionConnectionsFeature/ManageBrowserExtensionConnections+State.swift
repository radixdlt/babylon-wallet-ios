import Foundation
import InputPasswordFeature

// MARK: ManageBrowserExtensionConnections.State
public extension ManageBrowserExtensionConnections {
	struct State: Equatable {
		public var inputBrowserExtensionConnectionPassword: InputPassword.State?
		public init(
			inputBrowserExtensionConnectionPassword: InputPassword.State? = nil
		) {
			self.inputBrowserExtensionConnectionPassword = inputBrowserExtensionConnectionPassword
		}
	}
}
