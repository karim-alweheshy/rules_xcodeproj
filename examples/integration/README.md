# Integration Tests

This is an example of an extra file that is added to the Xcode project via
`extra_files`.

## Resource Previews

Open `MixedLib/MixedResourcePreviews.swift` in the generated project and enable
its Preview canvas. A successful resource Preview shows `Resource bundle loaded`,
`runtime-nested-resource`, the `PreviewPixel` image, and a `PreviewAccent` color
swatch. These exercise localized strings, a nested resource bundle, and compiled
asset catalogs. Missing bundles or nested text fail explicitly instead of
rendering placeholder content.
