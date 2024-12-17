
// MARK: - BannerClient + TestDependencyKey
extension OverlayWindowClient: TestDependencyKey {
	static let testValue = Self(
		scheduledItems: noop.scheduledItems,
		scheduleAlert: noop.scheduleAlert,
		scheduleAlertAndIgnoreAction: unimplemented("\(Self.self).scheduleAlertAndIgnoreAction"),
		scheduleHUD: unimplemented("\(Self.self).scheduleHUD"),
		scheduleSheet: unimplemented("\(Self.self).scheduleSheet"),
		scheduleFullScreen: noop.scheduleFullScreen,
		sendAlertAction: unimplemented("\(Self.self).sendAlertAction"),
		sendFullScreenAction: unimplemented("\(Self.self).sendFullScreenAction"),
		setIsUserIteractionEnabled: unimplemented("\(Self.self).setIsUserIteractionEnabled"),
		isUserInteractionEnabled: noop.isUserInteractionEnabled
	)

	static let noop = Self(
		scheduledItems: { AsyncLazySequence([]).eraseToAnyAsyncSequence() },
		scheduleAlert: { _ in .dismissed },
		scheduleAlertAndIgnoreAction: { _ in },
		scheduleHUD: { _ in },
		scheduleSheet: { _ in },
		scheduleFullScreen: { _ in .dismiss },
		sendAlertAction: { _, _ in },
		sendFullScreenAction: { _, _ in },
		setIsUserIteractionEnabled: { _ in },
		isUserInteractionEnabled: { AsyncLazySequence([]).eraseToAnyAsyncSequence() }
	)
}
