import PBXProj

extension ElementCreator {
    struct CreateFolderReference {
        private let createIdentifier: CreateIdentifier

        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(
            createIdentifier: CreateIdentifier,
            callable: @escaping Callable = Self.defaultCallable
        ) {
            self.createIdentifier = createIdentifier
            self.callable = callable
        }

        /// Creates a `PBXFileReference` element with `lastKnownFileType = folder`.
        ///
        /// This creates a folder reference that Xcode will automatically scan
        /// for files, rather than listing each file individually. This is the
        /// same approach used for `.xcassets` folders.
        func callAsFunction(
            name: String,
            parentBazelPath: BazelPath,
            bazelPathType: BazelPathType
        ) -> GroupChild.ElementAndChildren {
            return callable(
                /*name:*/ name,
                /*parentBazelPath:*/ parentBazelPath,
                /*bazelPathType:*/ bazelPathType,
                /*createIdentifier:*/ createIdentifier
            )
        }
    }
}

// MARK: - CreateFolderReference.Callable

extension ElementCreator.CreateFolderReference {
    typealias Callable = (
        _ name: String,
        _ parentBazelPath: BazelPath,
        _ bazelPathType: BazelPathType,
        _ createIdentifier: ElementCreator.CreateIdentifier
    ) -> GroupChild.ElementAndChildren

    static func defaultCallable(
        name: String,
        parentBazelPath: BazelPath,
        bazelPathType: BazelPathType,
        createIdentifier: ElementCreator.CreateIdentifier
    ) -> GroupChild.ElementAndChildren {
        let bazelPath = BazelPath(parent: parentBazelPath, path: name)

        // Create identifier for the folder reference
        let identifier = createIdentifier(
            path: bazelPath,
            name: name,
            type: .folderReference
        )

        // For folder references, we use a simple path-based sourceTree
        // The folder name becomes the path that Xcode will scan
        let content = #"""
{isa = PBXFileReference; lastKnownFileType = folder; path = \#(name); sourceTree = "<group>"; }
"""#

        let element = Element(
            name: name,
            object: Object(
                identifier: identifier,
                content: content
            ),
            sortOrder: .groupLike // Folders sort with groups, not files
        )

        // Folder references don't have children - Xcode scans them at runtime
        // No resolved repository since resolution happens when Xcode scans the folder
        return GroupChild.ElementAndChildren(
            bazelPath: bazelPath,
            element: element,
            resolvedRepository: nil,
            children: []
        )
    }
}
