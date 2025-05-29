import ballerina/http;

service /api/v1/processor on new http:Listener(9091) {

    resource function post messages() returns json|error {
        // Simulate processing messages
        json response = {"status": "success", "message": "Messages processed successfully"};
        return response;
    }
}
