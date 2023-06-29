import Dependencies

// MARK: - BannerClient + TestDependencyKey
extension OverlayWindowClient: TestDependencyKey {
	public static let testValue: Self = .init(
		scheduledItems: unimplemented("\(Self.self).scheduledItems"),
		scheduleAlert: unimplemented("\(Self.self).scheduleAlert"),
		scheduleHUD: unimplemented("\(Self.self).scheduleHUD"),
		sendAlertAction: unimplemented("\(Self.self).sendAlertAction")
	)
}
