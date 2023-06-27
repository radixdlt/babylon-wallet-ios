import Dependencies

// MARK: - BannerClient + TestDependencyKey
extension BannerClient: TestDependencyKey {
	public static let testValue: Self = .init(
		events: unimplemented("\(Self.self).setWindowScene"),
                scheduleAlert: unimplemented("\(Self.self).scheduleAlert"),
                scheduleHUD: unimplemented("\(Self.self).scheduleHUD")
	)
}
