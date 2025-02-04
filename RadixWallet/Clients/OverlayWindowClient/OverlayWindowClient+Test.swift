
// MARK: - BannerClient + TestDependencyKey
extension OverlayWindowClient: TestDependencyKey {
	static let testValue = Self(
		scheduledContent: noop.scheduledContent,
		scheduledStatus: noop.scheduledStatus,
		scheduleAlert: noop.scheduleAlert,
		scheduleAlertAndIgnoreAction: unimplemented("\(Self.self).scheduleAlertAndIgnoreAction"),
		scheduleHUD: unimplemented("\(Self.self).scheduleHUD"),
		scheduleSheet: unimplemented("\(Self.self).scheduleSheet"),
		scheduleFullScreen: noop.scheduleFullScreen,
		sendAlertAction: unimplemented("\(Self.self).sendAlertAction"),
		sendFullScreenAction: unimplemented("\(Self.self).sendFullScreenAction"),
		sendSheetAction: unimplemented("\(Self.self).sendSheetAction"),
		setIsContentUserIteractionEnabled: unimplemented("\(Self.self).setIsContentUserIteractionEnabled"),
		isContentUserInteractionEnabled: noop.isContentUserInteractionEnabled,
		setIsStatusUserIteractionEnabled: unimplemented("\(Self.self).setIsStatusUserIteractionEnabled"),
		isStatusUserInteractionEnabled: noop.isStatusUserInteractionEnabled
	)

	static let noop = Self(
		scheduledContent: { AsyncLazySequence([]).eraseToAnyAsyncSequence() },
		scheduledStatus: { AsyncLazySequence([]).eraseToAnyAsyncSequence() },
		scheduleAlert: { _ in .dismissed },
		scheduleAlertAndIgnoreAction: { _ in },
		scheduleHUD: { _ in },
		scheduleSheet: { _ in .dismiss },
		scheduleFullScreen: { _ in .dismiss },
		sendAlertAction: { _, _ in },
		sendFullScreenAction: { _, _ in },
		sendSheetAction: { _, _ in },
		setIsContentUserIteractionEnabled: { _ in },
		isContentUserInteractionEnabled: { AsyncLazySequence([]).eraseToAnyAsyncSequence() },
		setIsStatusUserIteractionEnabled: { _ in },
		isStatusUserInteractionEnabled: { AsyncLazySequence([]).eraseToAnyAsyncSequence() }
	)
}
