// from: https://github.com/apple/swift-crypto/blob/64a1a98e47e6643e6d43d30b87a244483b51d8ad/Sources/Crypto/Util/BoringSSL/RNG_boring.swift
// commit: 64a1a98e47e6643e6d43d30b87a244483b51d8ad

//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftCrypto open source project
//
// Copyright (c) 2019-2022 Apple Inc. and the SwiftCrypto project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.md for the list of SwiftCrypto project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

extension UnsafeMutableRawBufferPointer {
	public func initializeWithRandomBytes(count: Int) {
		guard count > 0 else {
			return
		}

		precondition(count <= self.count)
		var rng = SystemRandomNumberGenerator()

		// We store bytes 64-bits at a time until we can't anymore.
		var targetPtr = self
		while targetPtr.count > 8 {
			targetPtr.storeBytes(of: rng.next(), as: UInt64.self)
			targetPtr = UnsafeMutableRawBufferPointer(rebasing: targetPtr[8...])
		}

		// Now we're down to having to store things an integer at a time. We do this by shifting and
		// masking.
		var remainingWord: UInt64 = rng.next()
		while targetPtr.count > 0 {
			targetPtr.storeBytes(of: UInt8(remainingWord & 0xFF), as: UInt8.self)
			remainingWord >>= 8
			targetPtr = UnsafeMutableRawBufferPointer(rebasing: targetPtr[1...])
		}
	}
}
