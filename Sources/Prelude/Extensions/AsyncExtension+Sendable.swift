// MARK: - AnyAsyncIterator + Sendable
extension AnyAsyncIterator: @unchecked Sendable where Element: Sendable {}

// MARK: - AnyAsyncSequence + Sendable
extension AnyAsyncSequence: @unchecked Sendable where Element: Sendable {}

// MARK: - AsyncThrowingStream.Iterator + Sendable
extension AsyncThrowingStream.Iterator: @unchecked Sendable where Element: Sendable {}
