import Foundation
import SwiftUI

struct MixedResourcePreviews: PreviewProvider {
    private static let resources: Bundle = {
        let containingBundle = Bundle(for: MixedSwift.self)
        let candidates = [
            containingBundle.resourceURL,
            containingBundle.bundleURL.deletingLastPathComponent(),
            Bundle.main.resourceURL,
        ]
        for candidate in candidates.compactMap({ $0 }) {
            if let bundle = Bundle(
                url: candidate.appendingPathComponent("MixedLibResources.bundle")
            ) {
                return bundle
            }
        }
        fatalError("Missing MixedLibResources.bundle")
    }()

    private static var nestedValue: String {
        guard let nestedURL = resources.url(
            forResource: "MixedLibNestedResources",
            withExtension: "bundle"
        ),
            let nestedBundle = Bundle(url: nestedURL),
            let valueURL = nestedBundle.url(
                forResource: "value",
                withExtension: "txt"
            ),
            let value = try? String(contentsOf: valueURL, encoding: .utf8)
        else {
            fatalError("Missing nested Preview resource")
        }
        return value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static var previews: some View {
        VStack {
            Text("preview.title", bundle: resources)
            Text(nestedValue)
            Image("PreviewPixel", bundle: resources)
            Color("PreviewAccent", bundle: resources)
                .frame(width: 40, height: 40)
        }
        .padding()
    }
}
