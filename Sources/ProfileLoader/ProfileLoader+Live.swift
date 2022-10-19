import Profile
import KeychainClient
import Foundation

public extension JSONDecoder {
    static var iso8601: JSONDecoder {
        let jsonDecoder = JSONDecoder()
        jsonDecoder.dateDecodingStrategy = .iso8601
        return jsonDecoder
    }
}


public extension ProfileLoader {
	static func live(
        keychainClient: KeychainClient = .live(),
        jsonDecoder: JSONDecoder = .iso8601
	) -> Self {
		Self(
            loadProfileSnapshot: {
                try keychainClient.loadProfileSnapshot(jsonDecoder: jsonDecoder)
			}
		)
	}
}

// MARK: - ProfileLoader.Error
public extension ProfileLoader {
	enum Error: String, Swift.Error, Equatable {
		case failedToDecode
	}
}
