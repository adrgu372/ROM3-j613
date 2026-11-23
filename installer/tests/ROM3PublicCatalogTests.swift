#if os(macOS)
  import Foundation
  import XCTest
  @testable import AuroraAppleInstallerTrustCore

  final class ROM3PublicCatalogTests: XCTestCase {
    private let release = URL(
      string:
        "https://github.com/adrgu372/ROM3-j613/releases/download/image-20261122.6"
    )!

    func testPublicCatalogAdmitsJ613AndArtifactURLs() async throws {
      let descriptorData = try await fetch("release.json")
      let trustRootData = try await fetch("trust-root.ed25519.pub")
      let configuration = try InstallerReleaseConfigurationLoader().load(
        descriptor: descriptorData,
        trustRootPublicKey: trustRootData
      )
      XCTAssertEqual(configuration.defaultChannel, .testing)

      let documents = try await InstallerReleaseCatalogFetcher().fetch(
        configuration: configuration,
        channel: .testing
      )
      let catalog = try AppleInstallerTrustCore().validateSupportCatalog(
        payload: documents.payload,
        signature: documents.signature,
        trustRoot: configuration.trustRoot,
        now: Date()
      )
      try ReleaseCatalogChannelPolicy.validate(
        payload: documents.payload,
        channel: .testing
      )
      guard case .admitted(let installer) = catalog.admission(for: "apple,j613")
      else {
        return XCTFail("ROM3 catalog did not admit apple,j613")
      }
      XCTAssertEqual(installer.installationProfile, "arch-kde")
      let delivery = try XCTUnwrap(installer.delivery)
      XCTAssertEqual(delivery.payload.parts.count, 6)
      XCTAssertEqual(
        delivery.payload.sourceURL.lastPathComponent,
        "arch-kde-20261122.6.zip"
      )
      XCTAssertEqual(
        delivery.metadata.sourceURL.lastPathComponent,
        "installer-data-arch-kde.json"
      )

      try await head(delivery.metadata.sourceURL)
      for part in delivery.payload.parts {
        try await head(part.sourceURL)
      }
    }

    private func fetch(_ name: String) async throws -> Data {
      let (data, response) = try await URLSession.shared.data(
        from: release.appendingPathComponent(name)
      )
      let http = try XCTUnwrap(response as? HTTPURLResponse)
      XCTAssertEqual(http.statusCode, 200, name)
      return data
    }

    private func head(_ url: URL) async throws {
      var request = URLRequest(url: url)
      request.httpMethod = "HEAD"
      request.timeoutInterval = 30
      let (_, response) = try await URLSession.shared.data(for: request)
      let http = try XCTUnwrap(response as? HTTPURLResponse)
      XCTAssertTrue(
        (200...299).contains(http.statusCode),
        "\(url.lastPathComponent): HTTP \(http.statusCode)"
      )
    }
  }
#endif
