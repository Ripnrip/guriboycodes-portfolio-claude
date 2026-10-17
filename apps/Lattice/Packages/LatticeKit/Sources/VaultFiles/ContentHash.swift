import Foundation

/// A fast, stable 64-bit content hash used only to answer "did this file's bytes change".
///
/// FNV-1a rather than SHA-256 for two reasons: it needs no CryptoKit, so this target keeps
/// building on Linux and stays unit-testable off a Mac, and change detection does not need
/// collision resistance against an adversary — the file is already trusted, and size is
/// checked alongside the hash.
///
/// **Not** for signatures, deduplication across untrusted input, or anything security
/// relevant.
public enum ContentHash {
    private static let offsetBasis: UInt64 = 0xCBF2_9CE4_8422_2325
    private static let prime: UInt64 = 0x1_0000_01B3

    public static func hash(_ bytes: some Sequence<UInt8>) -> String {
        var value = offsetBasis
        for byte in bytes {
            value ^= UInt64(byte)
            value = value &* prime
        }
        return String(value, radix: 16)
    }

    public static func hash(_ text: String) -> String {
        hash(text.utf8)
    }

    public static func hash(of data: Data) -> String {
        hash(data)
    }
}
