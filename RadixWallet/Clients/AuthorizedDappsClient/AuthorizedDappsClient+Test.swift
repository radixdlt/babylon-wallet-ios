
extension DependencyValues {
	var authorizedDappsClient: AuthorizedDappsClient {
		get { self[AuthorizedDappsClient.self] }
		set { self[AuthorizedDappsClient.self] = newValue }
	}
}

// MARK: - AuthorizedDappsClient + TestDependencyKey
extension AuthorizedDappsClient: TestDependencyKey {
	static let previewValue = Self.noop

	static let testValue = Self(
		getAuthorizedDapps: unimplemented("\(Self.self).getAuthorizedDapps"),
		authorizedDappValues: unimplemented("\(Self.self).authorizedDappValues", placeholder: noop.authorizedDappValues),
		addAuthorizedDapp: unimplemented("\(Self.self).addAuthorizedDapp"),
		forgetAuthorizedDapp: unimplemented("\(Self.self).forgetAuthorizedDapp"),
		updateAuthorizedDapp: unimplemented("\(Self.self).updateAuthorizedDapp"),
		updateOrAddAuthorizedDapp: unimplemented("\(Self.self).updateOrAddAuthorizedDapp"),
		deauthorizePersonaFromDapp: unimplemented("\(Self.self).deauthorizePersonaFromDapp"),
		detailsForAuthorizedDapp: unimplemented("\(Self.self).detailsForAuthorizedDapp")
	)

	static let noop = Self(
		getAuthorizedDapps: { [] },
		authorizedDappValues: { AsyncLazySequence([]).eraseToAnyAsyncSequence() },
		addAuthorizedDapp: { _ in },
		forgetAuthorizedDapp: { _, _ in },
		updateAuthorizedDapp: { _ in },
		updateOrAddAuthorizedDapp: { _ in },
		deauthorizePersonaFromDapp: { _, _, _ in },
		detailsForAuthorizedDapp: { _ in throw NoopError() }
	)
}
