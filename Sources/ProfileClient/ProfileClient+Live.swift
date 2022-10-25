//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-10-25.
//

import Foundation
import Profile
import KeychainClient

public extension ProfileClient {
    static let live: Self = {
        let profileHolder = ProfileHolder.shared
        return Self(
            injectProfile: {
                profileHolder.injectProfile($0)
            },
            extractProfileSnapshot: {
                try profileHolder.takeProfileSnapshot()
            },
            deleteProfileSnapshot: {
                profileHolder.removeProfile()
            },
            getAccounts: {
                try profileHolder.get { profile in
                    profile.primaryNet.accounts
                }
            },
            getAppPreferences: {
                try profileHolder.get { profile in
                    profile.appPreferences
                }
            },
            setDisplayAppPreferences: { _ in
                try profileHolder.setting { _ in
                }
            },
            createAccountWithKeychainClient: { accountName, keychainClient in
                try await profileHolder.asyncSetting { profile in
                    try await profile.createNewOnLedgerAccount(
                        displayName: accountName,
                        makeEntityNonVirtualBySubmittingItToLedger: { _ in fatalError() },
                        mnemonicForFactorSourceByReference: { reference in
                            try keychainClient.loadFactorSourceMnemonic(reference: reference)
                        }
                    )
                }
            }
        )
    }()
}

// MARK: - ProfileHolder
private final class ProfileHolder {
    private var profile: Profile?
    private init() {}
    fileprivate static let shared = ProfileHolder()

    struct NoProfile: Swift.Error {}

    func removeProfile() {
        profile = nil
    }

    @discardableResult
    func get<T>(_ withProfile: (Profile) throws -> T) throws -> T {
        guard let profile else {
            throw NoProfile()
        }
        return try withProfile(profile)
    }

    @discardableResult
    func getAsync<T>(_ withProfile: (Profile) async throws -> T) async throws -> T {
        guard let profile else {
            throw NoProfile()
        }
        return try await withProfile(profile)
    }

    func setting(_ setProfile: (inout Profile) throws -> Void) throws {
        guard var profile else {
            throw NoProfile()
        }
        try setProfile(&profile)
        self.profile = profile
    }

    func asyncSetting<T>(_ setProfile: (inout Profile) async throws -> T) async throws -> T {
        guard var profile else {
            throw NoProfile()
        }
        let result = try await setProfile(&profile)
        self.profile = profile
        return result
    }

    func injectProfile(_ profile: Profile) {
        self.profile = profile
    }

    func takeProfileSnapshot() throws -> ProfileSnapshot {
        try get { profile in
            profile.snaphot()
        }
    }
}
