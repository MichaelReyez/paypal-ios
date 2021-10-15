import Foundation
#if canImport(PaymentsCore)
import PaymentsCore
#endif

public class CardClient2 {

    private let api: API
    private let decoder = JSONDecoder()

    /// Initialize a CardClient to process card payment
    /// - Parameter config: The CoreConfig object
    public convenience init(config: CoreConfig) {
        self.init(api: APIClient2(config: config))
    }

    /// For internal use for testing/mocking purpose
    init(api: API) {
        self.api = api
    }

    /// Approve an order with a card, which validates buyer's card, and if valid, attaches the card as the payment source to the order.
    /// After the order has been successfully approved, you will need to handle capturing/authorizing the order in your server.
    /// - Parameters:
    ///   - orderID: The ID of the order to be approved
    ///   - card: The card to be charged for this order
    ///   - completion: Completion handler for approveOrder, which contains data of the order if success, or an error if failure
    public func approveOrder(orderID: String, card: Card, completion: @escaping (Result<OrderData, Error>) -> Void) {
        let path = "/v2/checkout/orders/\(orderID)/confirm-payment-source"
        var request = APIRequest2(method: .post, path: path)
        request.body = ConfirmPaymentSourceBody(card: card)
        
        api.send(request) { response in
            let correlationID = response.headers["Paypal-Debug-Id"] as? String
            
            if response.status == 404 {
                completion(.failure(NetworkingError.unknown))
            } else {
                do {
                    let result = try self.parseResult(from: response)
                    let orderData = OrderData(orderID: result.id, status: OrderStatus(rawValue: result.status))
                    completion(.success(orderData))
                } catch {
                    completion(.failure(error))
                }
            }
        }
    }
    
    private func parseResult(from httpResponse: HttpResponse) throws -> ConfirmPaymentSourceResponse {
        var result: ConfirmPaymentSourceResponse!
        if let body = httpResponse.body {
            result = try? self.decoder.decode(ConfirmPaymentSourceResponse.self, from: body)
        }
        
        if result == nil {
            let error = NSError(domain: "com.paypal.ios", code: -1, userInfo: [ "reason": "parsing_error" ])
            throw NetworkingError.parsingError(error)
        }
        return result
    }
}