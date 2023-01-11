// MARK: - InformationRequest
public struct InformationRequest: Sendable, Codable, Hashable {}

// MARK: - InformationResponse
public struct InformationResponse: Sendable, Codable, Hashable {
	public let packageVersion: String
	public init(packageVersion: String) {
		self.packageVersion = packageVersion
	}

	private enum CodingKeys: String, CodingKey {
		case packageVersion = "package_version"
	}
}
