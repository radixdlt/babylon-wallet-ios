import Combine
import Sargon

// MARK: - AccessControllerClient + DependencyKey
extension AccessControllerClient: DependencyKey {
	typealias Value = AccessControllerClient

	static func live(
		refreshIntervalInSeconds: TimeInterval = 300 // 5 minutes
	) -> Self {
		let stateManager = AccessControllerStateManager(refreshIntervalInSeconds: refreshIntervalInSeconds)

		let getAllAccessControllerStateDetails: GetAllAccessControllerStateDetails = {
			try await stateManager.fetchAccessControllerStateDetails()
		}

		let getAccessControllerStateDetails: GetAccessControllerStateDetails = { address in
			if let details = try await getAllAccessControllerStateDetails().first(where: { $0.address == address }) {
				return details
			}
			throw MissingAccessControlerStateDetails(address: address)
		}

		let accessControllerStateDetailsUpdates: AccessControllerStateDetailsUpdates = {
			await stateManager.accessControllerStateDetailsStream()
		}

		let accessControllerUpdates: AccessControllerUpdates = { address in
			await stateManager.accessControllerStateDetailsStream()
				.map { allDetails in
					allDetails.first { $0.address == address }
				}
				.eraseToAnyAsyncSequence()
		}

		let forceRefresh: ForceRefresh = {
			await stateManager.forceRefresh()
		}

		return Self(
			getAllAccessControllerStateDetails: getAllAccessControllerStateDetails,
			getAccessControllerStateDetails: getAccessControllerStateDetails,
			accessControllerStateDetailsUpdates: accessControllerStateDetailsUpdates,
			accessControllerUpdates: accessControllerUpdates,
			forceRefresh: forceRefresh
		)
	}

	static let liveValue: Self = .live()
}

// MARK: - MissingAccessControlerStateDetails
struct MissingAccessControlerStateDetails: Error {
	let address: AccessControllerAddress
}

// MARK: - AccessControllerStateManager
private actor AccessControllerStateManager {
	private let refreshIntervalInSeconds: TimeInterval
	private let subject = AsyncReplaySubject<[AccessControllerStateDetails]>(bufferSize: 1)
	private var task: Task<Void, Never>?

	init(refreshIntervalInSeconds: TimeInterval) {
		self.refreshIntervalInSeconds = refreshIntervalInSeconds
		startPeriodicRefresh()
	}

	deinit {
		task?.cancel()
	}

	@discardableResult
	func fetchAccessControllerStateDetails() async throws -> [AccessControllerStateDetails] {
		let details = try await SargonOS.shared.fetchAllAccessControllersDetails()
		subject.send(details)
		return details
	}

	func accessControllerStateDetailsStream() -> AnyAsyncSequence<[AccessControllerStateDetails]> {
		subject.eraseToAnyAsyncSequence()
	}

	func forceRefresh() async {
		try? await fetchAccessControllerStateDetails()
	}

	private func startPeriodicRefresh() {
		task = Task { [weak self] in
			guard let self else { return }

			// Then fetch periodically
			while !Task.isCancelled {
				try? await self.fetchAccessControllerStateDetails()
				try? await Task.sleep(for: .seconds(refreshIntervalInSeconds))
				guard !Task.isCancelled else { return }
			}
		}
	}
}
