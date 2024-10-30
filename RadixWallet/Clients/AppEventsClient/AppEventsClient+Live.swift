extension AppEventsClient: DependencyKey {
	static let liveValue: AppEventsClient = {
		let eventsSubject = AsyncReplaySubject<AppEvent>(bufferSize: 10)

		return .init(
			handleEvent: { event in
				eventsSubject.send(event)
			},
			events: {
				eventsSubject.eraseToAnyAsyncSequence()
			}
		)
	}()
}
