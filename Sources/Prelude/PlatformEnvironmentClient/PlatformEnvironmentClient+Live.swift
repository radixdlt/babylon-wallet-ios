import Dependencies

extension PlatformEnvironmentClient: DependencyKey {
	public static let liveValue: Self = .init(
		isSimulator: {
			#if targetEnvironment(simulator)
			return true
			#else
			return false
			#endif
		}
	)
}
