// MARK: - InformationRequest
public struct InformationRequest: Sendable, Codable, Hashable {
	public init() {}
}

// MARK: - InformationResponse
public struct InformationResponse: Sendable, Codable, Hashable {
	public let packageVersion: String
	public let gitHash: String
	public init(packageVersion: String, gitHash: String) {
		self.packageVersion = packageVersion
		self.gitHash = gitHash
	}

	private enum CodingKeys: String, CodingKey {
		case packageVersion = "package_version"
		case gitHash = "git_hash"
	}
}
