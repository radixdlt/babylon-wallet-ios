import FeaturePrelude

// MARK: - ScanQR.State
public extension ScanQR {
	struct State: Equatable {
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
public extension ScanQR.State {
	static let previewValue: Self = .init()
}
#endif
