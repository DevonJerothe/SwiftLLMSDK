import Foundation

public protocol LanguageModelService {
    associatedtype ResponseType: ModelResponse

    var urlSession: URLSession { get}
    var baseURL: String { get }
    var timeoutInterval: TimeInterval { get }
    var apiKey: String? { get}

    func sendMessage(promptModel: RequestBodyBuilder) async -> Result<ResponseType, APIError>
}

extension LanguageModelService {

    func sendRequest<T: Decodable>(
        for: T.Type,
        path: String,
        method: String,
        requestBody: Data? = nil
    ) async -> Result<T, APIError> {
        guard let baseURL = URL(string: baseURL + path) else {
            return .failure(.invalidURL)
        }
        
        do {
            // Create the request
            var request = URLRequest(url: baseURL, timeoutInterval: timeoutInterval)
            request.httpMethod = method
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Jax AI", forHTTPHeaderField: "X-Title")

            // Set the API key if available
            if let apiKey {
                request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            }

            // Set the request body if provided
            if let requestBody {
                request.httpBody = requestBody
            }
            
            // Send the request
            let (data, response) = try await urlSession.data(for: request)
            
            // Check response status
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(.invalidResponse)
            }
            
            // Check for successful status code (200-299)
            if !(200...299).contains(httpResponse.statusCode) {
                return .failure(.serverError(code: httpResponse.statusCode))
            }
            
            // Decode the response
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            
            do {
                let decodedResponse = try decoder.decode(T.self, from: data)
                return .success(decodedResponse)
            } catch {
                return .failure(.decodingError)
            }
        } catch let error as URLError where error.code == .timedOut {
            return .failure(.timeout) // Handle timeout error
        } catch {
            return .failure(.invalidData)
        }
    }

    func getInt(endpoint: String) async -> Result<Int, APIError> {
        guard let baseURL = URL(string: baseURL + endpoint) else {
            return .failure(.invalidURL)
        }

        do {
            var request = URLRequest(url: baseURL, timeoutInterval: timeoutInterval)
            request.httpMethod = "GET"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            let (data, response) = try await urlSession.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(.invalidResponse)
            }

            if !(200...299).contains(httpResponse.statusCode) {
                return .failure(.serverError(code: httpResponse.statusCode))
            }

            do {
                let decoder = JSONDecoder()
                let intResponse = try decoder.decode(IntResponse.self, from: data)
                return .success(intResponse.value)
            } catch {
                return .failure(.decodingError)
            }

        } catch let error as URLError where error.code == .timedOut {
            return .failure(.timeout) // Handle timeout error
        } catch {
            return .failure(.invalidData)
        }
    }

    func getString(endpoint: String) async -> Result<String, APIError> {
        guard let baseURL = URL(string: baseURL + endpoint) else {
            return .failure(.invalidURL)
        }

        do {
            var request = URLRequest(url: baseURL, timeoutInterval: timeoutInterval)
            request.httpMethod = "GET"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            let (data, response) = try await urlSession.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(.invalidResponse)
            }

            if !(200...299).contains(httpResponse.statusCode) {
                return .failure(.serverError(code: httpResponse.statusCode))
            }

            do {
                let decoder = JSONDecoder()
                let stringResponse = try decoder.decode(StringResponse.self, from: data)
                return .success(stringResponse.result)
            } catch {
                return .failure(.decodingError)
            }
        } catch let error as URLError where error.code == .timedOut {
            return .failure(.timeout) // Handle timeout error
        } catch {
            return .failure(.invalidData)
        }
    }
}

