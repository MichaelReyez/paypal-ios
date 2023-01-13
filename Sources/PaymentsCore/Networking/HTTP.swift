import Foundation

/// `HTTP` interfaces directly with `URLSession` to execute network requests.
class HTTP {
    
    let coreConfig: CoreConfig
    private var urlSession: URLSessionProtocol
    private let jsonDecoder = JSONDecoder()

    init(urlSession: URLSessionProtocol = URLSession.shared, coreConfig: CoreConfig) {
        self.urlSession = urlSession
        self.coreConfig = coreConfig
        
        jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
    }
    
    func performRequest<T: APIRequest>(_ request: T) async throws -> (T.ResponseType) {
        guard let urlRequest = request.toURLRequest(environment: coreConfig.environment) else {
            throw APIClientError.invalidURLRequestError
        }
        
        let (data, response) = try await urlSession.performRequest(with: urlRequest)
        guard let response = response as? HTTPURLResponse else {
            throw APIClientError.invalidURLResponseError
        }

        switch response.statusCode {
        case 200..<300:
            do {
                return try jsonDecoder.decode(T.ResponseType.self, from: data)
            } catch {
                throw APIClientError.dataParsingError
            }
        default:
            let errorData: ErrorResponse
            do {
                errorData = try jsonDecoder.decode(ErrorResponse.self, from: data)
            } catch {
                throw APIClientError.unknownError
            }
            throw APIClientError.serverResponseError(errorData.readableDescription)
        }
    }
}
