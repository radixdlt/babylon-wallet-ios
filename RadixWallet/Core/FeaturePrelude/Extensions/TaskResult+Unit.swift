
extension TaskResult where Success == EqVoid {
	public init(catching body: @Sendable () async throws -> Void) async {
		do {
			try await body()
			self = .success(EqVoid.instance)
		} catch {
			self = .failure(error)
		}
	}
}
