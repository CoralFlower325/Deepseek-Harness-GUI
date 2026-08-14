import Foundation

struct HarnessPaths {
    let supportRoot: URL
    let runtimesRoot: URL
    let dshHome: URL
    let stateURL: URL
    let updateLogURL: URL
    let resourcesRoot: URL

    init(fileManager: FileManager = .default, bundle: Bundle = .main) throws {
        let applicationSupport = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        supportRoot = applicationSupport.appendingPathComponent("DeepSeekHarnessMac", isDirectory: true)
        runtimesRoot = supportRoot.appendingPathComponent("runtimes", isDirectory: true)
        dshHome = fileManager.homeDirectoryForCurrentUser.appendingPathComponent(".dsh", isDirectory: true)
        stateURL = supportRoot.appendingPathComponent("runtime-state.json")
        updateLogURL = supportRoot.appendingPathComponent("runtime-update.log")
        resourcesRoot = bundle.resourceURL ?? bundle.bundleURL.appendingPathComponent("Contents/Resources", isDirectory: true)

        try fileManager.createDirectory(at: supportRoot, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: runtimesRoot, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: dshHome, withIntermediateDirectories: true)
    }

    var bundledNodeURL: URL {
        resourcesRoot.appendingPathComponent("engine/bin/node")
    }

    var bundledNpmCLIURL: URL {
        resourcesRoot.appendingPathComponent("engine/node_modules/npm/bin/npm-cli.js")
    }

    var bundledNodeBinDirectory: URL {
        resourcesRoot.appendingPathComponent("engine/bin", isDirectory: true)
    }

    func runtimeRoot(for version: String) -> URL {
        runtimesRoot.appendingPathComponent(version, isDirectory: true)
    }
}
