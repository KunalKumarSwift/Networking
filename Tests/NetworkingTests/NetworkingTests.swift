import XCTest
import UIKit
@testable import Networking

// MARK: - MockURLProtocol

/// Intercepts URLSession requests in tests so no real network calls are made.
final class MockURLProtocol: URLProtocol, @unchecked Sendable {
    /// Set this before each test to control what the mock returns/throws.
    nonisolated(unsafe) static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.unknown))
            return
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

// MARK: - MockContentFetcher

final class MockContentFetcher: ContentFetcherProtocol, @unchecked Sendable {
    var stubbedResult: Result<Data, Error>

    init(result: Result<Data, Error>) {
        self.stubbedResult = result
    }

    func requestContent(request: URLRequest) async throws -> Data {
        switch stubbedResult {
        case .success(let data): return data
        case .failure(let error): throw error
        }
    }
}

// MARK: - MockURLBuilder

struct MockURLBuilder: SAURLBuilder {
    var endPoint: String
    var httpMethod: SAHttpMethod?
    var requestType: SARequestType?
}

// MARK: - MockServiceRequest

struct MockServiceRequest: SAServiceRequest {
    var endPoint: String = "/v1/planetary/apod"
    var httpMethod: SAHttpMethod? = .https
    var requestType: SARequestType? = .GET
    var contentFetcher: ContentFetcherProtocol
}

// MARK: - Helpers

private func makeMockSession() -> URLSession {
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [MockURLProtocol.self]
    return URLSession(configuration: config)
}

private func makeHTTPResponse(url: URL, statusCode: Int) -> HTTPURLResponse {
    HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
}

private func make1x1Image() -> UIImage {
    let renderer = UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1))
    return renderer.image { ctx in
        UIColor.red.setFill()
        ctx.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
    }
}

// MARK: - TestModel

private struct TestModel: Decodable, Sendable {
    let id: Int
    let name: String
}

// MARK: - NetworkRequestBuilderTests

final class NetworkRequestBuilderTests: XCTestCase {

    var sut: NetworkRequestBuilder!

    override func setUp() {
        super.setUp()
        sut = NetworkRequestBuilder()
    }

    // MARK: buildURLRequest(withURL:)

    func test_buildURLRequest_withURL_setsURL() {
        let url = URL(string: "https://api.example.com/test")!
        XCTAssertEqual(sut.buildURLRequest(withURL: url).url, url)
    }

    func test_buildURLRequest_withURL_setsCachePolicy() {
        let url = URL(string: "https://api.example.com/test")!
        XCTAssertEqual(sut.buildURLRequest(withURL: url).cachePolicy, .reloadRevalidatingCacheData)
    }

    func test_buildURLRequest_withURL_setsTimeout() {
        let url = URL(string: "https://api.example.com/test")!
        XCTAssertEqual(sut.buildURLRequest(withURL: url).timeoutInterval, 30)
    }

    // MARK: buildURLRequest(withURLBuilder:andParameters:)

    func test_buildURLRequest_withURLBuilder_setsScheme() throws {
        let builder = MockURLBuilder(endPoint: "/test", httpMethod: .https, requestType: .GET)
        let request = try sut.buildURLRequest(withURLBuilder: builder, andParameters: [:])
        XCTAssertEqual(request.url?.scheme, "https")
    }

    func test_buildURLRequest_withURLBuilder_setsHTTPMethod() throws {
        let builder = MockURLBuilder(endPoint: "/test", httpMethod: .https, requestType: .POST)
        let request = try sut.buildURLRequest(withURLBuilder: builder, andParameters: [:])
        XCTAssertEqual(request.httpMethod, "POST")
    }

    func test_buildURLRequest_withURLBuilder_setsBaseHost() throws {
        let builder = MockURLBuilder(endPoint: "/test", httpMethod: .https, requestType: .GET)
        let request = try sut.buildURLRequest(withURLBuilder: builder, andParameters: [:])
        XCTAssertEqual(request.url?.host, SANetworkConstant.baseURL)
    }

    func test_buildURLRequest_withURLBuilder_appendsAPIKey() throws {
        let builder = MockURLBuilder(endPoint: "/test", httpMethod: .https, requestType: .GET)
        let request = try sut.buildURLRequest(withURLBuilder: builder, andParameters: [:])
        let items = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)?.queryItems ?? []
        let apiKey = items.first { $0.name == SANetworkConstant.apiParameterKey }
        XCTAssertEqual(apiKey?.value, SANetworkConstant.apiKey)
    }

    func test_buildURLRequest_withURLBuilder_includesCustomParameters() throws {
        let builder = MockURLBuilder(endPoint: "/test", httpMethod: .https, requestType: .GET)
        let request = try sut.buildURLRequest(withURLBuilder: builder, andParameters: ["date": "2024-01-01"])
        let items = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)?.queryItems ?? []
        let date = items.first { $0.name == "date" }
        XCTAssertEqual(date?.value, "2024-01-01")
    }

    func test_buildURLRequest_withURLBuilder_sortsQueryItemsAlphabetically() throws {
        let builder = MockURLBuilder(endPoint: "/test", httpMethod: .https, requestType: .GET)
        let request = try sut.buildURLRequest(withURLBuilder: builder, andParameters: ["z_key": "z", "a_key": "a"])
        let names = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)?.queryItems?.map(\.name) ?? []
        XCTAssertEqual(names, names.sorted())
    }

    func test_buildURLRequest_withURLBuilder_setsCachePolicy() throws {
        let builder = MockURLBuilder(endPoint: "/test", httpMethod: .https, requestType: .GET)
        let request = try sut.buildURLRequest(withURLBuilder: builder, andParameters: [:])
        XCTAssertEqual(request.cachePolicy, .reloadRevalidatingCacheData)
    }

    func test_buildURLRequest_withURLBuilder_setsTimeout() throws {
        let builder = MockURLBuilder(endPoint: "/test", httpMethod: .https, requestType: .GET)
        let request = try sut.buildURLRequest(withURLBuilder: builder, andParameters: [:])
        XCTAssertEqual(request.timeoutInterval, SANetworkConstant.timeout)
    }
}

// MARK: - SAContentFetcherTests

final class SAContentFetcherTests: XCTestCase {

    var sut: SAContentFetcher!
    let testURL = URL(string: "https://api.nasa.gov/v1/test")!

    override func setUp() {
        super.setUp()
        sut = SAContentFetcher(session: makeMockSession())
    }

    override func tearDown() {
        MockURLProtocol.requestHandler = nil
        super.tearDown()
    }

    func test_requestContent_200_returnsData() async throws {
        let expected = Data("hello".utf8)
        MockURLProtocol.requestHandler = { [testURL] _ in (makeHTTPResponse(url: testURL, statusCode: 200), expected) }
        let data = try await sut.requestContent(request: URLRequest(url: testURL))
        XCTAssertEqual(data, expected)
    }

    func test_requestContent_202_returnsData() async throws {
        let expected = Data("accepted".utf8)
        MockURLProtocol.requestHandler = { [testURL] _ in (makeHTTPResponse(url: testURL, statusCode: 202), expected) }
        let data = try await sut.requestContent(request: URLRequest(url: testURL))
        XCTAssertEqual(data, expected)
    }

    func test_requestContent_404_throwsEncountered404() async {
        MockURLProtocol.requestHandler = { [testURL] _ in (makeHTTPResponse(url: testURL, statusCode: 404), Data()) }
        await assertThrows(SARequestError.encountered404) {
            _ = try await self.sut.requestContent(request: URLRequest(url: self.testURL))
        }
    }

    func test_requestContent_500_throwsOtherError() async {
        MockURLProtocol.requestHandler = { [testURL] _ in (makeHTTPResponse(url: testURL, statusCode: 500), Data()) }
        do {
            _ = try await sut.requestContent(request: URLRequest(url: testURL))
            XCTFail("Expected SARequestError.otherError")
        } catch SARequestError.otherError(let code) {
            XCTAssertEqual(code, 500)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func test_requestContent_networkError_throws() async {
        MockURLProtocol.requestHandler = { _ in throw URLError(.notConnectedToInternet) }
        do {
            _ = try await sut.requestContent(request: URLRequest(url: testURL))
            XCTFail("Expected URLError")
        } catch {
            XCTAssertTrue(error is URLError)
        }
    }
}

// MARK: - SAServiceRequestTests

final class SAServiceRequestTests: XCTestCase {

    func test_requestData_decodesValidJSON() async throws {
        let json = Data(#"{"id":1,"name":"Test"}"#.utf8)
        let sut = MockServiceRequest(contentFetcher: MockContentFetcher(result: .success(json)))
        let model: TestModel = try await sut.requestData(model: TestModel.self)
        XCTAssertEqual(model.id, 1)
        XCTAssertEqual(model.name, "Test")
    }

    func test_requestData_withParameters_decodesValidJSON() async throws {
        let json = Data(#"{"id":42,"name":"Param"}"#.utf8)
        let sut = MockServiceRequest(contentFetcher: MockContentFetcher(result: .success(json)))
        let model: TestModel = try await sut.requestData(withParameters: ["date": "2024-01-01"], model: TestModel.self)
        XCTAssertEqual(model.id, 42)
    }

    func test_requestData_networkError_throws() async {
        let sut = MockServiceRequest(contentFetcher: MockContentFetcher(result: .failure(SARequestError.encountered404)))
        await assertThrows(SARequestError.encountered404) {
            let _: TestModel = try await sut.requestData(model: TestModel.self)
        }
    }

    func test_requestData_invalidJSON_throwsDecodingError() async {
        let sut = MockServiceRequest(contentFetcher: MockContentFetcher(result: .success(Data("bad".utf8))))
        do {
            let _: TestModel = try await sut.requestData(model: TestModel.self)
            XCTFail("Expected DecodingError")
        } catch is DecodingError {
            // expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func test_requestData_otherNetworkError_throws() async {
        let sut = MockServiceRequest(contentFetcher: MockContentFetcher(result: .failure(SARequestError.otherError(errorCode: 503))))
        do {
            let _: TestModel = try await sut.requestData(model: TestModel.self)
            XCTFail("Expected SARequestError.otherError")
        } catch SARequestError.otherError(let code) {
            XCTAssertEqual(code, 503)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}

// MARK: - SAImageFetcherTests

@MainActor
final class SAImageFetcherTests: XCTestCase {

    var sut: SAImageFetcher!
    let testURL = URL(string: "https://example.com/image.png")!

    override func setUp() {
        super.setUp()
        SAImageFetcher.cache.removeAllObjects()
        sut = SAImageFetcher(session: makeMockSession())
    }

    override func tearDown() {
        MockURLProtocol.requestHandler = nil
        SAImageFetcher.cache.removeAllObjects()
        super.tearDown()
    }

    func test_fetchImage_nilURL_throwsImageURLNil() async {
        await assertThrows(ImageFetcherError.imageURLNil) {
            _ = try await self.sut.fetchImage(url: nil)
        }
    }

    func test_fetchImage_validData_returnsImage() async throws {
        let data = make1x1Image().pngData()!
        MockURLProtocol.requestHandler = { [testURL] _ in (makeHTTPResponse(url: testURL, statusCode: 200), data) }
        let image = try await sut.fetchImage(url: testURL)
        XCTAssertNotNil(image)
    }

    func test_fetchImage_storesImageInCache() async throws {
        let data = make1x1Image().pngData()!
        MockURLProtocol.requestHandler = { [testURL] _ in (makeHTTPResponse(url: testURL, statusCode: 200), data) }
        _ = try await sut.fetchImage(url: testURL)
        XCTAssertNotNil(SAImageFetcher.cache.object(forKey: testURL.absoluteString as NSString))
    }

    func test_fetchImage_usesCache_skipsNetwork() async throws {
        SAImageFetcher.cache.setObject(make1x1Image(), forKey: testURL.absoluteString as NSString)
        // Handler would throw if the network were hit
        MockURLProtocol.requestHandler = { _ in throw URLError(.unknown) }
        let image = try await sut.fetchImage(url: testURL)
        XCTAssertNotNil(image)
    }

    func test_fetchImage_invalidImageData_throwsUnableToFetch() async {
        MockURLProtocol.requestHandler = { [testURL] _ in
            (makeHTTPResponse(url: testURL, statusCode: 200), Data("not-an-image".utf8))
        }
        await assertThrows(ImageFetcherError.unableToFetchImage) {
            _ = try await self.sut.fetchImage(url: self.testURL)
        }
    }

    func test_fetchImage_networkFailure_throws() async {
        MockURLProtocol.requestHandler = { _ in throw URLError(.notConnectedToInternet) }
        do {
            _ = try await sut.fetchImage(url: testURL)
            XCTFail("Expected URLError")
        } catch {
            XCTAssertTrue(error is URLError)
        }
    }
}

// MARK: - XCTestCase + assertThrows

extension XCTestCase {
    /// Asserts that the async block throws a specific `Equatable` error.
    func assertThrows<E: Error & Equatable>(
        _ expected: E,
        file: StaticString = #file,
        line: UInt = #line,
        _ block: () async throws -> Void
    ) async {
        do {
            try await block()
            XCTFail("Expected \(expected) to be thrown", file: file, line: line)
        } catch let error as E {
            XCTAssertEqual(error, expected, file: file, line: line)
        } catch {
            XCTFail("Unexpected error type: \(error)", file: file, line: line)
        }
    }
}
