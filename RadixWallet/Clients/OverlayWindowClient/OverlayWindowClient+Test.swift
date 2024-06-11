
// MARK: - BannerClient + TestDependencyKey
extension OverlayWindowClient: TestDependencyKey {
	public static let testValue = Self(
		scheduledItems: unimplemented("\(Self.self).scheduledItems"),
		scheduleAlertIgnoreAction: unimplemented("\(Self.self).scheduleAlertIgnoreAction"),
		scheduleAlertAwaitAction: unimplemented("\(Self.self).scheduleAlertAwaitAction"),
		scheduleHUD: unimplemented("\(Self.self).scheduleHUD"),
		scheduleFullScreenIgnoreAction: unimplemented("\(Self.self).scheduleFullScreenIgnoreAction"),
		sendAlertAction: unimplemented("\(Self.self).sendAlertAction"),
		setIsUserIteractionEnabled: unimplemented("\(Self.self).setIsUserIteractionEnabled"),
		isUserInteractionEnabled: unimplemented("\(Self.self).isUserInteractionEnabled"),
		scheduleLinkingDapp: unimplemented("\(Self.self).scheduleLinkingDapp")
	)
}
