import Foundation

/// Just a namespace to disambigate certain publically facing high
/// abstraction application types used by consumer packages from
/// lower level EngineToolkit types used for Request to `radix-engine-toolkit`,
/// such as `PublicKey` and `Engine.PublicKey` where the former is
/// being used by Babylon Wallet and where the latter is more of an
/// internal type used as Request and Response to `radix-engine-toolkit` and
/// easily turned into `PublicKey` and created from `PublicKey`.
public enum Engine {}
