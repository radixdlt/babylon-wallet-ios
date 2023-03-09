// MARK: - InformationRequest
public struct InformationRequest: Sendable, Codable, Hashable {
	public init() {}
}

// MARK: - InformationResponse
public struct InformationResponse: Sendable, Codable, Hashable {
	public let packageVersion: String
	public let lastCommitHash: String
	public init(packageVersion: String, lastCommitHash: String) {
		self.packageVersion = packageVersion
		self.lastCommitHash = lastCommitHash
	}

	private enum CodingKeys: String, CodingKey {
		case packageVersion = "package_version"
		case lastCommitHash = "last_commit_hash"
	}
}
