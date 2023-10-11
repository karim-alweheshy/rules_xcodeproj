import Foundation

/// An `Error` that represents a programming error.
public struct PreconditionError: Error {
    public let message: String
    public let file: StaticString
    public let line: UInt

    public init(
        message: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        self.message = message
        self.file = file
        self.line = line
    }
}

extension PreconditionError: LocalizedError {
    public var errorDescription: String? {
        return """
Internal precondition failure:
\(file):\(line): \(message)
Please file a bug report at \
https://github.com/MobileNativeFoundation/rules_xcodeproj/issues/new?template=bug.md
"""
    }
}
