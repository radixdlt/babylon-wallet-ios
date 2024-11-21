// MARK: - AnyAsyncIterator + @unchecked Sendable
extension AnyAsyncIterator: @unchecked Sendable where Element: Sendable {}

// MARK: - AnyAsyncSequence + @unchecked Sendable
extension AnyAsyncSequence: @unchecked Sendable where Element: Sendable {}

// MARK: - AsyncThrowingStream.Iterator + @unchecked Sendable
extension AsyncThrowingStream.Iterator: @unchecked Sendable where Element: Sendable {}
