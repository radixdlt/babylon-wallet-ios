import FeaturePrelude

// MARK: - ScanQR.State
extension ScanQR {
	public struct State: Equatable {
		#if os(macOS) || (os(iOS) && targetEnvironment(simulator))
		public var connectionPassword: String

		public init(
			connectionPassword: String = ""
		) {
			self.connectionPassword = connectionPassword
		}
		#else
		public init() {}
		#endif // macOS
	}
}

#if DEBUG
extension ScanQR.State {
	public static let previewValue: Self = .init()
}
#endif
