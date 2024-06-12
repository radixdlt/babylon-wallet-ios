
// MARK: - BannerClient + TestDependencyKey
extension OverlayWindowClient: TestDependencyKey {
	public static let testValue = Self(
		scheduledItems: unimplemented("\(Self.self).scheduledItems"),
		scheduleAlert: unimplemented("\(Self.self).scheduleAlert"),
		scheduleAlertAndIgnoreAction: unimplemented("\(Self.self).scheduleAlertAndIgnoreAction"),
		scheduleHUD: unimplemented("\(Self.self).scheduleHUD"),
		scheduleFullScreen: unimplemented("\(Self.self).scheduleFullScreen"),
		sendAlertAction: unimplemented("\(Self.self).sendAlertAction"),
		sendFullScreenAction: unimplemented("\(Self.self).sendFullScreenAction"),
		setIsUserIteractionEnabled: unimplemented("\(Self.self).setIsUserIteractionEnabled"),
		isUserInteractionEnabled: unimplemented("\(Self.self).isUserInteractionEnabled"),
		scheduleLinkingDapp: unimplemented("\(Self.self).scheduleLinkingDapp")
	)
}
