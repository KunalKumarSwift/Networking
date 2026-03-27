# Networking

A lightweight Swift networking library for iOS, providing URL request building, JSON decoding, and image fetching with a clean protocol-based API.

## Requirements

- iOS 15+
- Swift 5.3+
- Xcode 13+

## Installation

### Swift Package Manager

Add the package to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/KunalKumarSwift/Networking.git", from: "1.0.0")
]
```

Or add it via Xcode: **File > Add Packages** and enter the repository URL.

## Modules

| File | Description |
|------|-------------|
| `SARequestFoundation.swift` | Core protocols and enums (`SAURLBuilder`, `SAHttpMethod`, `SARequestType`, `SARequestError`) |
| `SARequestBuilder.swift` | `NetworkRequestBuilder` — constructs `URLRequest` from a `SAURLBuilder` conformer |
| `SAContentFetcher.swift` | `SAContentFetcher` — performs network requests, returns `Data` via completion handler |
| `SAServiceRequest.swift` | `SAServiceRequest` protocol — fetches and decodes `Decodable` models |
| `SAImageFetcher.swift` | `SAImageFetcher` — fetches and caches `UIImage` objects |
| `SANetworkConstants.swift` | Base URL, API key, and timeout constants |

## Usage

### Define an endpoint

Conform any type to `SAURLBuilder` to describe an endpoint:

```swift
struct MoviesEndpoint: SAURLBuilder {
    var endPoint: String { "/movies" }
    var httpMethod: SAHttpMethod? { .https }
    var requestType: SARequestType? { .GET }
}
```

### Build a URLRequest

```swift
let builder = NetworkRequestBuilder()
let request = try builder.buildURLRequest(
    withURLBuilder: MoviesEndpoint(),
    andParameters: ["page": "1"]
)
```

### Fetch and decode a model

Conform your endpoint to `SAServiceRequest` and call `requestData`:

```swift
struct MoviesEndpoint: SAServiceRequest {
    var endPoint: String { "/movies" }
    var httpMethod: SAHttpMethod? { .https }
    var requestType: SARequestType? { .GET }
    var contentFetcher: ContentFetcherProtocol? { SAContentFetcher.shared }
}

struct MoviesResponse: Decodable {
    let results: [Movie]
}

try MoviesEndpoint().requestData(model: MoviesResponse.self) { result in
    guard let movies = result as? MoviesResponse else { return }
    print(movies.results)
}
```

### Fetch an image

```swift
let fetcher = SAImageFetcher()
fetcher.fetchImage(url: URL(string: "https://example.com/photo.jpg")) { result in
    switch result {
    case .success(let image):
        DispatchQueue.main.async { imageView.image = image }
    case .failure(let error):
        print("Image fetch failed: \(error)")
    }
}
```

Images are automatically cached in memory via `NSCache`. Subsequent requests for the same URL return the cached image without a network call.

## Error Handling

| Error | Meaning |
|-------|---------|
| `SARequestError.encountered404` | Server returned HTTP 404 |
| `SARequestError.otherError(errorCode:)` | Any other non-success HTTP status |
| `BuilderError.unableBuildURL(message:)` | Could not construct a valid URL from the given components |
| `ImageFetcherError.imageURLNil` | `nil` URL passed to `SAImageFetcher` |
| `ImageFetcherError.unableToFetchImage` | Network failure or response could not be decoded as an image |

## Branches

| Branch | Description |
|--------|-------------|
| `main` | Swift 5.3 baseline, completion-handler API |
| `claude/swift-6-migration-jAMbp` | Swift 6 migration — `async/await`, `Sendable`, `@MainActor` |
| `crypto-library` | Adds [SACrypto](Crypto/README.md) — a standalone Swift 6 cryptography library |

## License

See [LICENSE](LICENSE).
