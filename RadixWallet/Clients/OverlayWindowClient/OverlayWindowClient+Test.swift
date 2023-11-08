
// MARK: - BannerClient + TestDependencyKey
extension OverlayWindowClient: TestDependencyKey {
	public static let testValue = Self(
		scheduledItems: unimplemented("\(Self.self).scheduledItems"),
		scheduleAlertIgnoreAction: unimplemented("\(Self.self).scheduleAlertIgnoreAction"),
		scheduleAlertAwaitAction: unimplemented("\(Self.self).scheduleAlertAwaitAction"),
		scheduleHUD: unimplemented("\(Self.self).scheduleHUD"),
		sendAlertAction: unimplemented("\(Self.self).sendAlertAction"),
		setIsUserIteractionEnabled: unimplemented("\(Self.self).setIsUserIteractionEnabled"),
		isUserInteractionEnabled: unimplemented("\(Self.self).isUserInteractionEnabled")
	)
}
