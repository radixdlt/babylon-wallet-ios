import Prelude

extension TaskResult where Success == HashableVoid {
	public init(catching body: @Sendable () async throws -> Void) async {
		do {
			try await body()
			self = .success(HashableVoid())
		} catch {
			self = .failure(error)
		}
	}
}
