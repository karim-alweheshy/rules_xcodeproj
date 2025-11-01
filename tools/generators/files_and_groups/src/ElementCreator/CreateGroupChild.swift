import PBXProj

extension ElementCreator {
    struct CreateGroupChild {
        private let createFile: CreateFile
        private let createFolderReference: CreateFolderReference
        private let createGroup: CreateGroup
        private let createInlineBazelGeneratedFiles:
            ElementCreator.CreateInlineBazelGeneratedFiles
        private let createLocalizedFiles: CreateLocalizedFiles
        private let createVersionGroup: CreateVersionGroup
        private let folderReferenceDirectories: Set<String>

        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(
            createFile: CreateFile,
            createFolderReference: CreateFolderReference,
            createGroup: CreateGroup,
            createInlineBazelGeneratedFiles:
                ElementCreator.CreateInlineBazelGeneratedFiles,
            createLocalizedFiles: CreateLocalizedFiles,
            createVersionGroup: CreateVersionGroup,
            folderReferenceDirectories: [String] = [],
            callable: @escaping Callable
        ) {
            self.createFile = createFile
            self.createFolderReference = createFolderReference
            self.createGroup = createGroup
            self.createInlineBazelGeneratedFiles =
                createInlineBazelGeneratedFiles
            self.createLocalizedFiles = createLocalizedFiles
            self.createVersionGroup = createVersionGroup
            self.folderReferenceDirectories = Set(folderReferenceDirectories)
            self.callable = callable
        }

        func callAsFunction(
            for node: PathTreeNode,
            parentBazelPath: BazelPath,
            parentBazelPathType: BazelPathType
        ) -> GroupChild {
            return callable(
                /*node:*/ node,
                /*parentBazelPath:*/ parentBazelPath,
                /*parentBazelPathType:*/ parentBazelPathType,
                /*createFile:*/ createFile,
                /*createFolderReference:*/ createFolderReference,
                /*createGroup:*/ createGroup,
                /*createGroupChild:*/ self,
                /*createInlineBazelGeneratedFiles:*/
                    createInlineBazelGeneratedFiles,
                /*createLocalizedFiles:*/ createLocalizedFiles,
                /*createVersionGroup:*/ createVersionGroup
            )
        }
    }
}

// MARK: - CreateGroupChild.Callable

extension ElementCreator.CreateGroupChild {
    typealias Callable = (
        _ node: PathTreeNode,
        _ parentBazelPath: BazelPath,
        _ parentBazelPathType: BazelPathType,
        _ createFile: ElementCreator.CreateFile,
        _ createFolderReference: ElementCreator.CreateFolderReference,
        _ createGroup: ElementCreator.CreateGroup,
        _ createGroupChild: ElementCreator.CreateGroupChild,
        _ createInlineBazelGeneratedFiles:
            ElementCreator.CreateInlineBazelGeneratedFiles,
        _ createLocalizedFiles: ElementCreator.CreateLocalizedFiles,
        _ createVersionGroup: ElementCreator.CreateVersionGroup
    ) -> GroupChild

    static func defaultCallable(
        for node: PathTreeNode,
        parentBazelPath: BazelPath,
        parentBazelPathType: BazelPathType,
        createFile: ElementCreator.CreateFile,
        createFolderReference: ElementCreator.CreateFolderReference,
        createGroup: ElementCreator.CreateGroup,
        createGroupChild: ElementCreator.CreateGroupChild,
        createInlineBazelGeneratedFiles:
            ElementCreator.CreateInlineBazelGeneratedFiles,
        createLocalizedFiles: ElementCreator.CreateLocalizedFiles,
        createVersionGroup: ElementCreator.CreateVersionGroup
    ) -> GroupChild {
        switch node {
        case .group(let name, let children):
            // Check if this folder should be treated as a folder reference
            if shouldUseFolderReference(name: name, parentBazelPath: parentBazelPath) {
                return .elementAndChildren(
                    createFolderReference(
                        name: name,
                        parentBazelPath: parentBazelPath,
                        bazelPathType: parentBazelPathType
                    )
                )
            }

            let (basenameWithoutExt, ext) = name.splitExtension()
            switch ext {
            case "lproj":
                return .localizedRegion(
                    createLocalizedFiles(
                        name: name,
                        nodeChildren: children,
                        parentBazelPath: parentBazelPath,
                        region: basenameWithoutExt
                    )
                )

            case "xcdatamodeld":
                return .elementAndChildren(
                    createVersionGroup(
                        name: name,
                        nodeChildren: children,
                        parentBazelPath: parentBazelPath,
                        bazelPathType: parentBazelPathType
                    )
                )

            default:
                return .elementAndChildren(
                    createGroup(
                        name: name,
                        nodeChildren: children,
                        parentBazelPath: parentBazelPath,
                        bazelPathType: parentBazelPathType,
                        createGroupChild: createGroupChild
                    )
                )
            }

        case .file(let name):
            return .elementAndChildren(
                createFile(
                    name: name,
                    bazelPath: BazelPath(
                        parent: parentBazelPath,
                        path: name
                    ),
                    bazelPathType: parentBazelPathType,
                    transitiveBazelPaths: []
                )
            )

        case .generatedFiles(let generatedFiles):
            return .elementAndChildren(
                createInlineBazelGeneratedFiles(
                    for: generatedFiles,
                    createGroupChild: createGroupChild
                )
            )
        }
    }
}

struct Element: Equatable {
    enum SortOrder: Comparable {
        case groupLike
        case inlineBazelGenerated
        case fileLike
        case bazelExternalRepositories
        case rulesXcodeprojInternal
    }

    let name: String
    let object: Object
    let sortOrder: SortOrder
}

enum GroupChild: Equatable {
    struct ElementAndChildren {
        let element: Element
        let transitiveObjects: [Object]
        let bazelPathAndIdentifiers: [(BazelPath, String)]
        let knownRegions: Set<String>
        let resolvedRepositories: [ResolvedRepository]
    }

    struct LocalizedFile: Equatable {
        let element: Element
        let region: String
        let name: String
        let basenameWithoutExt: String
        let ext: String?
        let bazelPaths: [BazelPath]
    }

    case elementAndChildren(ElementAndChildren)
    case localizedRegion([LocalizedFile])
}

extension GroupChild.ElementAndChildren {
    init(
        bazelPath: BazelPath,
        element: Element,
        resolvedRepository: ResolvedRepository?,
        children: [GroupChild.ElementAndChildren]
    ) {
        var bazelPathAndIdentifiers: [(BazelPath, String)] = []
        var knownRegions: Set<String> = []
        var resolvedRepositories: [ResolvedRepository] = []
        var transitiveObjects: [Object] = []
        for child in children {
            bazelPathAndIdentifiers
                .append(contentsOf: child.bazelPathAndIdentifiers)
            knownRegions.formUnion(child.knownRegions)
            resolvedRepositories.append(contentsOf: child.resolvedRepositories)
            transitiveObjects.append(contentsOf: child.transitiveObjects)
        }

        bazelPathAndIdentifiers.append((bazelPath, element.object.identifier))
        transitiveObjects.append(element.object)

        if let resolvedRepository {
            resolvedRepositories.append(resolvedRepository)
        }

        self.init(
            element: element,
            transitiveObjects: transitiveObjects,
            bazelPathAndIdentifiers: bazelPathAndIdentifiers,
            knownRegions: knownRegions,
            resolvedRepositories: resolvedRepositories
        )
    }

    init(
        bazelPath: BazelPath,
        element: Element,
        includeParentInBazelPathAndIdentifiers: Bool = true,
        resolvedRepository: ResolvedRepository?,
        children: GroupChildElements
    ) {
        var bazelPathAndIdentifiers = children.bazelPathAndIdentifiers
        if includeParentInBazelPathAndIdentifiers {
            bazelPathAndIdentifiers.append((bazelPath, element.object.identifier))
        }

        var transitiveObjects = children.transitiveObjects
        transitiveObjects.append(element.object)

        var resolvedRepositories = children.resolvedRepositories
        if let resolvedRepository {
            resolvedRepositories.append(resolvedRepository)
        }

        self.init(
            element: element,
            transitiveObjects: transitiveObjects,
            bazelPathAndIdentifiers: bazelPathAndIdentifiers,
            knownRegions: children.knownRegions,
            resolvedRepositories: resolvedRepositories
        )
    }
}

extension GroupChild.ElementAndChildren: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        guard lhs.bazelPathAndIdentifiers.count ==
            rhs.bazelPathAndIdentifiers.count
        else {
            return false
        }

        for (lhsPair, rhsPair) in zip(
            lhs.bazelPathAndIdentifiers,
            rhs.bazelPathAndIdentifiers
        ) {
            guard lhsPair == rhsPair else {
                return false
            }
        }

        return (
            lhs.element,
            lhs.transitiveObjects,
            lhs.knownRegions,
            lhs.resolvedRepositories
        ) == (
            rhs.element,
            rhs.transitiveObjects,
            rhs.knownRegions,
            rhs.resolvedRepositories
        )
    }
}

// MARK: - Folder Reference Detection

extension ElementCreator.CreateGroupChild {
    /// Determines if a group should be treated as a folder reference
    /// instead of recursively enumerating its files.
    ///
    /// Folder references are only used for top-level directories whose names
    /// match the configured `folderReferenceDirectories` set. This provides
    /// significant file size reduction for large projects (95%+).
    private func shouldUseFolderReference(
        name: String,
        parentBazelPath: BazelPath
    ) -> Bool {
        // Only consider top-level folders (parent path is empty or root)
        guard parentBazelPath.path.isEmpty else {
            return false
        }

        // Check if this directory name is in the configured set
        return folderReferenceDirectories.contains(name)
    }
}
